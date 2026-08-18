import { getDb, persistNow } from '../config/database';
import { documents, analysisResults, clauses, jurisdictionFlags } from '../models';
import { sql } from 'drizzle-orm';
import { callWithFallback } from './ai';
import { parseAiResponse } from '../prompts/analysisPrompt';
import { getLanguageName, isSupportedLanguage } from '../config/languages';
import { BadRequestError, NotFoundError } from '../utils/errors';

interface TranslationSnapshot {
  language: string;
  summary: string;
  clauses: Array<{ id: number; plainEnglishText: string; riskReason: string | null; counterSuggestion: string | null }>;
  flags: Array<{ id: number; message: string }>;
  translatedAt: string;
  partial?: boolean;
}

const BATCH_SIZE = Number(process.env.TRANSLATE_BATCH_SIZE || 8);
const MAX_FIELD = Number(process.env.TRANSLATE_MAX_FIELD_CHARS || 600);

function clip(text: string | null | undefined, max = MAX_FIELD): string {
  if (!text) return '';
  const t = String(text).trim();
  if (t.length <= max) return t;
  return `${t.slice(0, max - 1)}…`;
}

function looksTranslated(text: string, targetLanguage: string): boolean {
  if (!text || targetLanguage === 'en') return true;
  if (targetLanguage === 'hi' || targetLanguage === 'mr') {
    return /[\u0900-\u097F]/.test(text);
  }
  return text.trim().length > 0;
}

function normalizeClauses(
  raw: unknown,
  fallback: TranslationSnapshot['clauses'],
): TranslationSnapshot['clauses'] {
  if (!Array.isArray(raw)) return fallback;
  return raw.map((item, i) => {
    const fb = fallback[i] || fallback.find((f) => f.id === (item as { id?: number })?.id) || {
      id: i + 1,
      plainEnglishText: '',
      riskReason: null,
      counterSuggestion: null,
    };
    if (!item || typeof item !== 'object') return fb;
    const m = item as Record<string, unknown>;
    return {
      id: Number(m.id) || fb.id,
      plainEnglishText: String(m.plainEnglishText ?? m.plain_english_text ?? fb.plainEnglishText ?? ''),
      riskReason: m.riskReason != null ? String(m.riskReason) : fb.riskReason,
      counterSuggestion: m.counterSuggestion != null ? String(m.counterSuggestion) : fb.counterSuggestion,
    };
  });
}

function normalizeFlags(
  raw: unknown,
  fallback: TranslationSnapshot['flags'],
): TranslationSnapshot['flags'] {
  if (!Array.isArray(raw)) return fallback;
  return raw.map((item, i) => {
    const fb = fallback[i] || { id: i + 1, message: '' };
    if (!item || typeof item !== 'object') return fb;
    const m = item as Record<string, unknown>;
    return {
      id: Number(m.id) || fb.id,
      message: String(m.message ?? fb.message ?? ''),
    };
  });
}

async function askTranslateJson(
  systemPrompt: string,
  userPrompt: string,
  targetLanguage: string,
): Promise<Record<string, unknown>> {
  const { response } = await callWithFallback(
    { systemPrompt, userPrompt, temperature: 0.1, maxTokens: 4096, expectJson: true },
    { task: 'rewrite', language: targetLanguage },
  );

  const text = typeof response.text === 'string' ? response.text : JSON.stringify(response.text);
  try {
    return parseAiResponse(text);
  } catch (firstErr) {
    const { response: repaired } = await callWithFallback(
      {
        systemPrompt:
          'Fix the following into valid JSON only. Keep the same keys and meaning. No markdown, no commentary.',
        userPrompt: text.slice(0, 8000),
        temperature: 0,
        maxTokens: 4096,
        expectJson: true,
      },
      { task: 'rewrite', language: targetLanguage },
    );
    const repairedText =
      typeof repaired.text === 'string' ? repaired.text : JSON.stringify(repaired.text);
    try {
      return parseAiResponse(repairedText);
    } catch {
      throw firstErr;
    }
  }
}

export async function translateAnalysisResults(
  documentId: number,
  userId: number,
  targetLanguage: string,
): Promise<TranslationSnapshot> {
  if (!isSupportedLanguage(targetLanguage)) {
    throw new BadRequestError(`Unsupported language: ${targetLanguage}`);
  }

  const db = getDb();
  const docRows = db.select().from(documents).where(
    sql`${documents.id} = ${documentId} AND ${documents.userId} = ${userId} AND ${documents.isDeleted} = 0`
  ).all();
  if (!docRows[0]) throw new NotFoundError('Document');

  const analysisRows = db.select().from(analysisResults).where(
    sql`${analysisResults.documentId} = ${documentId}`
  ).all();
  const analysis = analysisRows[0];
  if (!analysis) throw new BadRequestError('No analysis to translate. Analyze the document first.');

  let existing: Record<string, TranslationSnapshot> = {};
  try {
    existing = JSON.parse(analysis.translations || '{}');
  } catch {
    existing = {};
  }

  if (existing[targetLanguage] && !existing[targetLanguage].partial) {
    return existing[targetLanguage];
  }

  const clauseRows = db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysis.id}`).all();
  const flagRows = db.select().from(jurisdictionFlags).where(
    sql`${jurisdictionFlags.analysisId} = ${analysis.id}`
  ).all();

  const fallbackClauses = clauseRows.map((c) => ({
    id: c.id,
    plainEnglishText: c.plainEnglishText || '',
    riskReason: c.riskReason,
    counterSuggestion: c.counterSuggestion,
  }));
  const fallbackFlags = flagRows.map((f) => ({ id: f.id, message: f.message }));

  const langName = getLanguageName(targetLanguage);
  const systemPrompt = `You translate legal analysis UI text into ${langName} (${targetLanguage}).
Return ONLY one JSON object with keys: summary (string), clauses (array of {id, plainEnglishText, riskReason, counterSuggestion}), flags (array of {id, message}).
Keep ids unchanged. No markdown fences. No extra keys. No commentary.`;

  let summary = analysis.summary || '';
  let translatedFlags = fallbackFlags;
  let partial = false;

  try {
    const header = await askTranslateJson(
      systemPrompt,
      JSON.stringify({
        summary: clip(analysis.summary, 900),
        clauses: [],
        flags: fallbackFlags.map((f) => ({ id: f.id, message: clip(f.message, 240) })),
      }),
      targetLanguage,
    );
    summary = String(header.summary || summary);
    translatedFlags = normalizeFlags(header.flags, fallbackFlags);
  } catch (err) {
    console.warn('[translate] summary/flags failed:', err instanceof Error ? err.message : err);
    partial = true;
  }

  const translatedClauses: TranslationSnapshot['clauses'] = [];
  for (let i = 0; i < fallbackClauses.length; i += BATCH_SIZE) {
    const batch = fallbackClauses.slice(i, i + BATCH_SIZE).map((c) => ({
      id: c.id,
      plainEnglishText: clip(c.plainEnglishText),
      riskReason: clip(c.riskReason, 240) || null,
      counterSuggestion: clip(c.counterSuggestion, 240) || null,
    }));
    try {
      const parsed = await askTranslateJson(
        systemPrompt,
        JSON.stringify({ summary: '', clauses: batch, flags: [] }),
        targetLanguage,
      );
      translatedClauses.push(...normalizeClauses(parsed.clauses, batch));
    } catch (err) {
      console.warn('[translate] batch failed:', err instanceof Error ? err.message : err);
      translatedClauses.push(...batch);
      partial = true;
    }
  }

  if (!looksTranslated(summary, targetLanguage)) partial = true;

  const snapshot: TranslationSnapshot = {
    language: targetLanguage,
    summary,
    clauses: translatedClauses.length > 0 ? translatedClauses : fallbackClauses,
    flags: translatedFlags,
    translatedAt: new Date().toISOString(),
    partial,
  };

  existing[targetLanguage] = snapshot;
  db.run(sql`UPDATE ${analysisResults} SET translations = ${JSON.stringify(existing)} WHERE id = ${analysis.id}`);
  persistNow();

  return snapshot;
}
