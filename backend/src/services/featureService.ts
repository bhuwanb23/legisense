import { getDb } from '../config/database';
import { documents, analysisResults, clauses } from '../models';
import { sql } from 'drizzle-orm';
import { BadRequestError } from '../utils/errors';
import { callWithFallback } from './ai';
import { parseAiResponse } from '../prompts/analysisPrompt';
import { decryptText, isEncryptionConfigured } from './encryptionService';
import { getPromptForType } from '../prompts/promptTemplates';
import { appendLanguageInstructions } from '../prompts/analysisPrompt';
import { CONTRACT_TEMPLATES, findTemplate } from '../data/contractTemplates';
import { DOCUMENT_TYPES } from '../data/documentTypes';

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
  const docRows = await db.select().from(documents).where(
    sql`${documents.id} = ${documentId} AND ${documents.userId} = ${userId} AND ${documents.isDeleted} = 0`
  );
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

  const analysis = (await db.select().from(analysisResults).where(
    sql`${analysisResults.documentId} = ${documentId}`
  ))[0];
  const clauseRows = analysis
    ? await db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysis.id}`)
    : [];
  const counters = clauseRows
    .filter((c) => (c.counterSuggestion || '').trim())
    .map((c) => ({
      number: c.clauseNumber,
      title: c.clauseTitle,
      suggestion: c.counterSuggestion,
    }));
  let missing: string[] = [];
  try {
    missing = JSON.parse(analysis?.missingClauses || '[]');
    if (!Array.isArray(missing)) missing = [];
  } catch {
    missing = [];
  }

  const jurisdiction = [doc.countryCode, doc.stateCode].filter(Boolean).join('-') || 'general';

  const heuristicRewrite = () => {
    const sections = clauseRows.map((c) => {
      const body = (c.counterSuggestion || c.originalText || c.plainEnglishText || '').trim();
      const heading = [c.clauseNumber, c.clauseTitle].filter(Boolean).join('. ');
      return `${heading}\n${body}`.trim();
    }).filter(Boolean);
    const missingBlock = missing.length
      ? `\n\nADDITIONAL PROTECTIONS\n${missing.map((m, i) => `${i + 1}. ${m}`).join('\n')}`
      : '';
    const rewrittenText = `${sections.join('\n\n')}${missingBlock}`.trim() || rawText;
    const changes = [
      ...counters.slice(0, 8).map((c) => `Replaced ${c.title || `clause ${c.number}`} with a fairer counter-clause.`),
      ...missing.slice(0, 5).map((m) => `Added missing protection: ${m}`),
    ];
    if (changes.length === 0) changes.push('Neutralized one-sided terms using stored analysis.');
    return { rewrittenText, changes, model: 'heuristic-fallback' };
  };

  let responseText = '';
  let model = 'heuristic-fallback';
  try {
    const { response } = await callWithFallback({
      systemPrompt: `You are a legal advisor helping a regular person negotiate a fairer contract.
Rewrite the ENTIRE document below into a more balanced version that protects both parties fairly.
- Keep every clause from the original
- Replace risky clauses using the provided counter-suggestions
- Add any missing critical/recommended protections listed
- Neutralize one-sided terms (unlimited liability, one-sided termination, auto-renewal traps)
- Keep legally valid language in jurisdiction: ${jurisdiction}
- Do NOT invent new parties
- Return ONLY a JSON object: {"rewrittenText": "the full rewritten document", "changes": ["bullet summary of key changes"]}
- changes MUST list at least 3 concrete edits
- No markdown fences, no commentary.`,
      userPrompt: JSON.stringify({
        originalDocument: rawText.slice(0, 18000),
        counterSuggestions: counters.slice(0, 20),
        missingClauses: missing.slice(0, 12),
      }),
      temperature: 0.3,
      maxTokens: 8192,
      expectJson: true,
    }, { task: 'rewrite' });
    responseText = typeof response.text === 'string' ? response.text : JSON.stringify(response.text);
    model = response.model;
  } catch (err) {
    console.warn('[better-version] AI failed, using stored counters:', err instanceof Error ? err.message : err);
    return heuristicRewrite();
  }

  const text = responseText;
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

  let changes = Array.isArray(parsed.changes)
    ? parsed.changes.map(stringifyChange).filter(Boolean)
    : [];
  if (changes.length === 0 && rewritten.length > 80) {
    changes = counters.slice(0, 5).map((c) => `Rewrote ${c.title || `clause ${c.number}`} using a fairer counter-clause.`);
    if (missing[0]) changes.push(`Added missing protection: ${missing[0]}`);
    if (changes.length === 0) changes.push('Rewrote one-sided terms into a more balanced draft.');
  }

  return {
    rewrittenText: rewritten,
    changes,
    model,
  };
}

/**
 * Side-by-side comparison of two analyzed documents. Matches clauses by
 * normalized title/number, then labels each as added / removed / changed /
 * same. Returns both document names and the diff list.
 */
export interface WordDiff {
  word: string;
  type: 'added' | 'removed' | 'same';
}

export interface DiffClause {
  number: number | null;
  title: string | null;
  status: 'added' | 'removed' | 'modified' | 'unchanged';
  textA: string | null;
  textB: string | null;
  original_text: string | null;
  new_text: string | null;
  riskA: string | null;
  riskB: string | null;
  word_diff: WordDiff[];
  newRisksIntroduced: string[];
}

function normalizeTitle(title: string | null | undefined): string {
  return (title || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tokenize(text: string): string[] {
  return text.split(/(\s+)/).filter((t) => t.length > 0);
}

export function computeWordDiff(a: string, b: string): WordDiff[] {
  const left = tokenize(a || '');
  const right = tokenize(b || '');
  const n = left.length;
  const m = right.length;
  const dp: number[][] = Array.from({ length: n + 1 }, () => Array(m + 1).fill(0));
  for (let i = n - 1; i >= 0; i--) {
    for (let j = m - 1; j >= 0; j--) {
      dp[i][j] = left[i] === right[j] ? dp[i + 1][j + 1] + 1 : Math.max(dp[i + 1][j], dp[i][j + 1]);
    }
  }
  const out: WordDiff[] = [];
  let i = 0;
  let j = 0;
  while (i < n && j < m) {
    if (left[i] === right[j]) {
      out.push({ word: left[i], type: 'same' });
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      out.push({ word: left[i], type: 'removed' });
      i++;
    } else {
      out.push({ word: right[j], type: 'added' });
      j++;
    }
  }
  while (i < n) out.push({ word: left[i++], type: 'removed' });
  while (j < m) out.push({ word: right[j++], type: 'added' });
  return out;
}

function riskRank(level: string | null | undefined): number {
  const l = (level || '').toLowerCase();
  if (l === 'high' || l === 'critical') return 3;
  if (l === 'medium') return 2;
  if (l === 'low') return 1;
  return 0;
}

function toDiff(
  cA: typeof clauses.$inferSelect | null,
  cB: typeof clauses.$inferSelect | null,
  status: DiffClause['status'],
): DiffClause {
  const c = cA || cB;
  const textA = cA?.originalText ?? null;
  const textB = cB?.originalText ?? null;
  const word_diff = status === 'modified' ? computeWordDiff(textA || '', textB || '') : [];
  const newRisksIntroduced: string[] = [];
  if (cB && riskRank(cB.riskLevel) >= 3 && riskRank(cA?.riskLevel) < 3) {
    newRisksIntroduced.push(cB.clauseTitle || `Clause ${cB.clauseNumber}`);
  } else if (cB && status === 'modified' && (cB.riskScore ?? 0) > (cA?.riskScore ?? 0) + 10 && (cB.riskScore ?? 0) >= 70) {
    newRisksIntroduced.push(cB.clauseTitle || `Clause ${cB.clauseNumber}`);
  } else if (!cA && cB && riskRank(cB.riskLevel) >= 3) {
    newRisksIntroduced.push(cB.clauseTitle || `Clause ${cB.clauseNumber}`);
  }
  return {
    number: c?.clauseNumber ?? null,
    title: c?.clauseTitle ?? null,
    status,
    textA,
    textB,
    original_text: textA,
    new_text: textB,
    riskA: cA?.riskLevel ?? null,
    riskB: cB?.riskLevel ?? null,
    word_diff,
    newRisksIntroduced,
  };
}

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
  newRisksIntroduced: string[];
  summary: { changes: number; newRisks: number };
}> {
  const db = getDb();
  const docs = await db.select().from(documents).where(
    sql`${documents.id} IN (${documentIdA}, ${documentIdB}) AND ${documents.userId} = ${userId} AND ${documents.isDeleted} = 0`
  );
  if (docs.length !== 2) throw new BadRequestError('Both documents must exist and belong to you');

  const byId = new Map(docs.map((d) => [d.id, d]));
  const a = byId.get(documentIdA)!;
  const b = byId.get(documentIdB)!;

  const getAnalysis = async (docId: number) => {
    const rows = await db.select().from(analysisResults).where(
      sql`${analysisResults.documentId} = ${docId}`
    );
    return rows[0] || null;
  };

  const analysisA = await getAnalysis(documentIdA);
  const analysisB = await getAnalysis(documentIdB);
  if (!analysisA || !analysisB) throw new BadRequestError('Both documents need a completed analysis to compare');

  const clausesA = (await db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysisA.id}`))
    .sort((x, y) => (x.clauseNumber || 0) - (y.clauseNumber || 0));
  const clausesB = (await db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysisB.id}`))
    .sort((x, y) => (x.clauseNumber || 0) - (y.clauseNumber || 0));

  const strip = (s: string | null | undefined) => (s || '').toLowerCase().replace(/\s+/g, ' ').trim();
  const unusedB = [...clausesB];
  const removed: DiffClause[] = [];
  const changed: DiffClause[] = [];
  const same: DiffClause[] = [];

  for (const cA of clausesA) {
    const titleA = normalizeTitle(cA.clauseTitle);
    let idx = unusedB.findIndex((cB) => normalizeTitle(cB.clauseTitle) === titleA && titleA.length > 0);
    if (idx < 0 && cA.clauseNumber != null) {
      idx = unusedB.findIndex((cB) => cB.clauseNumber === cA.clauseNumber && !normalizeTitle(cB.clauseTitle));
    }
    if (idx < 0) {
      const pos = (cA.clauseNumber || 0) - 1;
      if (pos >= 0 && pos < unusedB.length && !normalizeTitle(unusedB[pos].clauseTitle)) {
        idx = pos;
      }
    }
    if (idx < 0) {
      removed.push(toDiff(cA, null, 'removed'));
      continue;
    }
    const cB = unusedB.splice(idx, 1)[0];
    if (strip(cA.originalText).slice(0, 800) === strip(cB.originalText).slice(0, 800)) {
      same.push(toDiff(cA, cB, 'unchanged'));
    } else {
      changed.push(toDiff(cA, cB, 'modified'));
    }
  }

  const added = unusedB.map((c) => toDiff(null, c, 'added'));
  const newRisksIntroduced = [...changed, ...added].flatMap((d) => d.newRisksIntroduced);

  return {
    docA: { id: a.id, title: a.originalName },
    docB: { id: b.id, title: b.originalName },
    added,
    removed,
    changed,
    same,
    totalA: clausesA.length,
    totalB: clausesB.length,
    newRisksIntroduced: [...new Set(newRisksIntroduced)],
    summary: {
      changes: added.length + removed.length + changed.length,
      newRisks: new Set(newRisksIntroduced).size,
    },
  };
}

/** List the domain templates available for upload pre-selection. */
export function listTemplates() {
  const bodyTypes = new Set(CONTRACT_TEMPLATES.map((t) => t.type));
  return DOCUMENT_TYPES.filter((t) => t.type !== 'unknown').map((t) => ({
    type: t.type,
    typeLabel: t.typeLabel,
    icon: t.icon,
    subTypes: t.subTypes,
    hasBody: bodyTypes.has(t.type),
  }));
}

export function buildTemplatePrompt(type: string, rawText: string, language = 'en') {
  return appendLanguageInstructions(getPromptForType(type), language, language);
}

export function getTemplate(type: string, jurisdiction?: string) {

  const tpl = findTemplate(type, jurisdiction);
  if (!tpl) return null;
  return tpl;
}

export async function exportTemplate(type: string, format: 'pdf' | 'docx', jurisdiction?: string): Promise<{ buffer: Buffer; filename: string; contentType: string }> {
  const tpl = getTemplate(type, jurisdiction);
  if (!tpl) throw new BadRequestError('Template not found');
  const { generatePdfBuffer, generateDocxBuffer } = await import('./exportReportService');
  const data = {
    documentTitle: tpl.title,
    riskScore: 20,
    summary: `Fair ${tpl.type} template for ${tpl.jurisdiction}.`,
    clauses: tpl.body.split(/\n\n+/).filter(Boolean).map((para, i) => ({
      title: `Section ${i + 1}`,
      plainEnglish: para,
      riskLevel: 'low',
    })),
    deadlines: [],
  };
  if (format === 'docx') {
    const buffer = await generateDocxBuffer(data);
    return { buffer, filename: `${tpl.type}.docx`, contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' };
  }
  const buffer = await generatePdfBuffer(data);
  return { buffer, filename: `${tpl.type}.pdf`, contentType: 'application/pdf' };
}

export async function compareDocumentToTemplate(documentId: number, type: string, userId: number, jurisdiction?: string) {
  const tpl = getTemplate(type, jurisdiction);
  if (!tpl) throw new BadRequestError('Template not found');
  const db = getDb();
  const doc = (await db.select().from(documents).where(
    sql`${documents.id} = ${documentId} AND ${documents.userId} = ${userId} AND ${documents.isDeleted} = 0`
  ))[0];
  if (!doc) throw new BadRequestError('Document not found');
  const analysis = (await db.select().from(analysisResults).where(sql`${analysisResults.documentId} = ${documentId}`))[0];
  if (!analysis) throw new BadRequestError('Analyze the document first');
  const clauseRows = await db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysis.id}`);
  const tplSections = tpl.body.split(/\n\n+/).filter(Boolean);
  const changed: Array<{ title: string; documentText: string; templateText: string; word_diff: WordDiff[] }> = [];
  for (const c of clauseRows) {
    const title = normalizeTitle(c.clauseTitle);
    const match = tplSections.find((s) => normalizeTitle(s.slice(0, 80)).includes(title.slice(0, 20)) || title && s.toLowerCase().includes(title.split(' ')[0] || '___'));
    if (!match) continue;
    const word_diff = computeWordDiff(match, c.originalText || '');
    changed.push({
      title: c.clauseTitle || 'Clause',
      documentText: c.originalText || '',
      templateText: match,
      word_diff,
    });
  }
  return {
    template: { type: tpl.type, title: tpl.title, jurisdiction: tpl.jurisdiction },
    documentId,
    deviations: changed,
    summary: `${changed.length} clauses compared against the fair ${tpl.type} template.`,
  };
}
