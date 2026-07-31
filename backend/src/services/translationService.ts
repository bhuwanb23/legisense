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
}

const MAX_CLAUSES = Number(process.env.TRANSLATE_MAX_CLAUSES || 6);
const MAX_FIELD = Number(process.env.TRANSLATE_MAX_FIELD_CHARS || 280);

function clip(text: string | null | undefined, max = MAX_FIELD): string {
  if (!text) return '';
  const t = String(text).trim();
  if (t.length <= max) return t;
  return `${t.slice(0, max - 1)}…`;
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
    { systemPrompt, userPrompt, temperature: 0.1, maxTokens: 2048 },
    { task: 'rewrite', language: targetLanguage },
  );

  const text = typeof response.text === 'string' ? response.text : JSON.stringify(response.text);
  try {
    return parseAiResponse(text);
  } catch (firstErr) {
    // One repair pass for tiny models
    const { response: repaired } = await callWithFallback(
      {
        systemPrompt:
          'Fix the following into valid JSON only. Keep the same keys and meaning. No markdown, no commentary.',
        userPrompt: text.slice(0, 6000),
        temperature: 0,
        maxTokens: 2048,
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

  if (existing[targetLanguage]) {
    return existing[targetLanguage];
  }

  const clauseRows = db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysis.id}`).all();
  const flagRows = db.select().from(jurisdictionFlags).where(
    sql`${jurisdictionFlags.analysisId} = ${analysis.id}`
  ).all();

  // Compact payload — tiny local models choke on large clause arrays.
  const compactClauses = clauseRows.slice(0, MAX_CLAUSES).map((c) => ({
    id: c.id,
    plainEnglishText: clip(c.plainEnglishText),
    riskReason: clip(c.riskReason, 160) || null,
    counterSuggestion: null as string | null,
  }));

  const compactFlags = flagRows.slice(0, 5).map((f) => ({
    id: f.id,
    message: clip(f.message, 160),
  }));

  const payload = {
    summary: clip(analysis.summary, 600),
    clauses: compactClauses,
    flags: compactFlags,
  };

  const langName = getLanguageName(targetLanguage);
  const systemPrompt = `You translate legal analysis UI text into ${langName} (${targetLanguage}).
Return ONLY one JSON object with keys: summary (string), clauses (array of {id, plainEnglishText, riskReason}), flags (array of {id, message}).
Keep ids unchanged. No markdown fences. No extra keys. No commentary.`;

  let parsed: Record<string, unknown>;
  try {
    parsed = await askTranslateJson(systemPrompt, JSON.stringify(payload), targetLanguage);
  } catch (err) {
    console.warn(
      '[translate] full payload failed, falling back to summary-only:',
      err instanceof Error ? err.message : err,
    );
    // Minimal fallback: translate summary only so the UI still updates.
    try {
      parsed = await askTranslateJson(
        `Translate the "summary" field into ${langName}. Return ONLY JSON: {"summary":"...","clauses":[],"flags":[]}`,
        JSON.stringify({ summary: payload.summary }),
        targetLanguage,
      );
    } catch (err2) {
      console.error('[translate] summary-only also failed:', err2 instanceof Error ? err2.message : err2);
      throw new BadRequestError(
        'Translation failed — the local model returned invalid JSON. Try again or use a larger model.',
      );
    }
  }

  const snapshot: TranslationSnapshot = {
    language: targetLanguage,
    summary: String(parsed.summary || analysis.summary || ''),
    clauses: normalizeClauses(parsed.clauses, compactClauses),
    flags: normalizeFlags(parsed.flags, compactFlags),
    translatedAt: new Date().toISOString(),
  };

  // Merge remaining untranslated clauses as English originals so UI still has full set.
  if (clauseRows.length > compactClauses.length) {
    const translatedIds = new Set(snapshot.clauses.map((c) => c.id));
    for (const c of clauseRows) {
      if (translatedIds.has(c.id)) continue;
      snapshot.clauses.push({
        id: c.id,
        plainEnglishText: c.plainEnglishText || '',
        riskReason: c.riskReason,
        counterSuggestion: c.counterSuggestion,
      });
    }
  }

  existing[targetLanguage] = snapshot;
  db.run(sql`UPDATE ${analysisResults} SET translations = ${JSON.stringify(existing)} WHERE id = ${analysis.id}`);
  persistNow();

  return snapshot;
}
