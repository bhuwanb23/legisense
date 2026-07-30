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

  const payload = {
    summary: analysis.summary,
    clauses: clauseRows.map((c) => ({
      id: c.id,
      plainEnglishText: c.plainEnglishText,
      riskReason: c.riskReason,
      counterSuggestion: c.counterSuggestion,
    })),
    flags: flagRows.map((f) => ({ id: f.id, message: f.message })),
  };

  const systemPrompt = `You translate legal analysis UI text. Return ONLY valid JSON with the same structure as the input.
Translate narrative fields into ${getLanguageName(targetLanguage)} (${targetLanguage}).
Keep ids unchanged. Do not invent new clauses. Keep legal terms that lack a natural translation and add a short explanation in parentheses.`;

  const { response } = await callWithFallback(
    {
      systemPrompt,
      userPrompt: JSON.stringify(payload),
      temperature: 0.2,
    },
    { task: 'rewrite', language: targetLanguage },
  );

  const parsed = typeof response.text === 'string' ? parseAiResponse(response.text) : response.text;

  const snapshot: TranslationSnapshot = {
    language: targetLanguage,
    summary: String((parsed as { summary?: string }).summary || analysis.summary || ''),
    clauses: Array.isArray((parsed as { clauses?: unknown }).clauses)
      ? (parsed as { clauses: TranslationSnapshot['clauses'] }).clauses
      : payload.clauses.map((c) => ({
          id: c.id,
          plainEnglishText: c.plainEnglishText || '',
          riskReason: c.riskReason,
          counterSuggestion: c.counterSuggestion,
        })),
    flags: Array.isArray((parsed as { flags?: unknown }).flags)
      ? (parsed as { flags: TranslationSnapshot['flags'] }).flags
      : payload.flags,
    translatedAt: new Date().toISOString(),
  };

  existing[targetLanguage] = snapshot;
  db.run(sql`UPDATE ${analysisResults} SET translations = ${JSON.stringify(existing)} WHERE id = ${analysis.id}`);
  persistNow();

  return snapshot;
}
