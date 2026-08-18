import { getDb } from '../config/database';
import { documents, analysisResults, clauses } from '../models';
import { sql } from 'drizzle-orm';
import { callWithFallback } from './ai';
import { parseAiResponse } from '../prompts/analysisPrompt';
import { decryptText, isEncryptionConfigured } from './encryptionService';
import { getPromptForType } from '../prompts/promptTemplates';
import { appendLanguageInstructions } from '../prompts/analysisPrompt';

/**
 * One-click "Better Version": ask the AI to rewrite the whole document into a
 * fairer, more balanced version. Returns the rewritten text plus a short list
 * of what changed.
 */
export async function generateBetterVersion(
  documentId: number,
  userId: number,
): Promise<{ rewrittenText: string; changes: string[]; model: string }> {
  const db = getDb();
  const docRows = db.select().from(documents).where(
    sql`${documents.id} = ${documentId} AND ${documents.userId} = ${userId} AND ${documents.isDeleted} = 0`
  ).all();
  const doc = docRows[0];
  if (!doc) throw new Error('Document not found');

  let rawText = doc.rawText || '';
  if (doc.encryptionIv && isEncryptionConfigured()) {
    try {
      rawText = decryptText(rawText, doc.encryptionIv);
    } catch {
      // Fall through with whatever we have
    }
  }
  if (!rawText || rawText.trim().length === 0) {
    throw new Error('Document text not available. Extract text and analyze first.');
  }

  const jurisdiction = [doc.countryCode, doc.stateCode].filter(Boolean).join('-') || 'general';

  const { response } = await callWithFallback({
    systemPrompt: `You are a legal advisor helping a regular person negotiate a fairer contract.
Rewrite the ENTIRE document below into a more balanced version that protects both parties fairly.
- Keep every clause from the original
- Neutralize one-sided terms (unlimited liability, one-sided termination, auto-renewal traps)
- Keep legally valid language in jurisdiction: ${jurisdiction}
- Do NOT invent new parties or obligations
- Return ONLY a JSON object: {"rewrittenText": "the full rewritten document", "changes": ["bullet summary of key changes"]}
- No markdown fences, no commentary.`,
    userPrompt: `Original document:\n\n${rawText.slice(0, 24000)}`,
    temperature: 0.3,
    maxTokens: 8192,
  }, { task: 'rewrite' });

  const text = typeof response.text === 'string' ? response.text : JSON.stringify(response.text);
  let parsed: Record<string, unknown>;
  try {
    parsed = parseAiResponse(text);
  } catch {
    // Tiny models sometimes return plain text — treat the whole reply as the rewrite.
    parsed = { rewrittenText: text, changes: [] };
  }

  let rewritten = String(parsed.rewrittenText || text).trim();
  // Tiny models occasionally double-wrap: {"rewrittenText":"{\"rewrittenText\":...}"}
  if (rewritten.startsWith('{') && rewritten.includes('"rewrittenText"')) {
    try {
      const inner = parseAiResponse(rewritten);
      if (inner.rewrittenText) rewritten = String(inner.rewrittenText).trim();
    } catch {
      // keep outer value
    }
  }

  const stringifyChange = (c: unknown): string => {
    if (typeof c === 'string') return c.trim();
    if (c && typeof c === 'object') {
      const o = c as Record<string, unknown>;
      const pick = o.text || o.change || o.description || o.title || o.summary;
      if (typeof pick === 'string' && pick.trim()) return pick.trim();
      try { return JSON.stringify(c); } catch { return String(c); }
    }
    return String(c ?? '').trim();
  };

  return {
    rewrittenText: rewritten,
    changes: Array.isArray(parsed.changes)
      ? parsed.changes.map(stringifyChange).filter(Boolean)
      : [],
    model: response.model,
  };
}

/**
 * Side-by-side comparison of two analyzed documents. Matches clauses by
 * normalized title/number, then labels each as added / removed / changed /
 * same. Returns both document names and the diff list.
 */
export async function compareDocuments(
  documentIdA: number,
  documentIdB: number,
  userId: number,
): Promise<{
  docA: { id: number; title: string };
  docB: { id: number; title: string };
  added: DiffClause[];
  removed: DiffClause[];
  changed: DiffClause[];
  same: DiffClause[];
  totalA: number;
  totalB: number;
}> {
  const db = getDb();
  const docs = db.select().from(documents).where(
    sql`${documents.id} IN (${documentIdA}, ${documentIdB}) AND ${documents.userId} = ${userId} AND ${documents.isDeleted} = 0`
  ).all();
  if (docs.length !== 2) throw new Error('Both documents must exist and belong to you');

  const byId = new Map(docs.map((d) => [d.id, d]));
  const a = byId.get(documentIdA)!;
  const b = byId.get(documentIdB)!;

  const getAnalysis = (docId: number) => {
    const rows = db.select().from(analysisResults).where(
      sql`${analysisResults.documentId} = ${docId}`
    ).all();
    return rows[0] || null;
  };

  const analysisA = getAnalysis(documentIdA);
  const analysisB = getAnalysis(documentIdB);
  if (!analysisA || !analysisB) throw new Error('Both documents need a completed analysis to compare');

  const getClauses = (analysisId: number) => {
    return db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysisId}`).all();
  };

  const clausesA = getClauses(analysisA.id);
  const clausesB = getClauses(analysisB.id);

  const key = (c: { clauseNumber: number | null; clauseTitle: string | null }) =>
    `${String(c.clauseNumber ?? '')}|${(c.clauseTitle || '').toLowerCase().trim()}`;

  const strip = (s: string | null | undefined) => (s || '').toLowerCase().replace(/\s+/g, ' ').trim();
  const normText = (c: { originalText: string | null }) => strip(c.originalText).slice(0, 500);

  const mapB = new Map<string, typeof clausesB[number]>();
  for (const c of clausesB) {
    const k = key(c);
    if (!mapB.has(k)) mapB.set(k, c);
  }

  const removed: DiffClause[] = [];
  const changed: DiffClause[] = [];
  const same: DiffClause[] = [];

  for (const cA of clausesA) {
    const k = key(cA);
    const cB = mapB.get(k);
    if (!cB) {
      removed.push(toDiff(cA, null));
      continue;
    }
    if (normText(cA) === normText(cB)) {
      same.push(toDiff(cA, cB));
    } else {
      changed.push(toDiff(cA, cB));
    }
    mapB.delete(k);
  }

  const added = [...mapB.values()].map((c) => toDiff(null, c));

  return {
    docA: { id: a.id, title: a.originalName },
    docB: { id: b.id, title: b.originalName },
    added,
    removed,
    changed,
    same,
    totalA: clausesA.length,
    totalB: clausesB.length,
  };
}

export interface DiffClause {
  number: number | null;
  title: string | null;
  textA: string | null;
  textB: string | null;
  riskA: string | null;
  riskB: string | null;
}

function toDiff(
  cA: typeof clauses.$inferSelect | null,
  cB: typeof clauses.$inferSelect | null,
): DiffClause {
  const c = cA || cB;
  return {
    number: c?.clauseNumber ?? null,
    title: c?.clauseTitle ?? null,
    textA: cA?.originalText ?? null,
    textB: cB?.originalText ?? null,
    riskA: cA?.riskLevel ?? null,
    riskB: cB?.riskLevel ?? null,
  };
}

/** List the domain templates available for upload pre-selection. */
export function listTemplates() {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const { DOCUMENT_TYPES } = require('../data/documentTypes') as typeof import('../data/documentTypes');
  return DOCUMENT_TYPES.filter((t) => t.type !== 'unknown').map((t) => ({
    type: t.type,
    typeLabel: t.typeLabel,
    icon: t.icon,
    subTypes: t.subTypes,
  }));
}

export function buildTemplatePrompt(type: string, rawText: string, language = 'en') {
  return appendLanguageInstructions(getPromptForType(type), language, language);
}
