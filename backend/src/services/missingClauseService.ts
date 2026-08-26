import { getDb, persistNow } from '../config/database';
import { clauses, analysisResults, requiredClausesTemplates } from '../models';
import { sql } from 'drizzle-orm';
import { callWithFallback } from './ai';
import { parseAiResponse } from '../prompts/analysisPrompt';

export interface StructuredMissingClause {
  name: string;
  importance: string;
  why_needed: string;
  is_confirmed_missing: boolean;
  is_incomplete?: boolean;
  related_clause_id?: number | null;
}

function normalizeDocType(raw: string | null | undefined): string {
  if (!raw) return 'unknown';
  const lower = raw.toLowerCase().trim().replace(/\s+/g, '_').replace(/-/g, '_');
  if (lower.includes('nda') || lower.includes('non_disclosure') || lower.includes('confidential')) return 'nda';
  if (lower.includes('rent') || lower.includes('lease')) return 'rental_agreement';
  if (lower.includes('employ')) return 'employment_contract';
  if (lower.includes('freelance')) return 'freelance_agreement';
  if (lower.includes('loan')) return 'loan_agreement';
  if (lower.includes('service')) return 'service_agreement';
  return lower;
}

function parseKeywords(raw: string | null): string[] {
  if (!raw) return [];
  try {
    const v = JSON.parse(raw);
    return Array.isArray(v) ? v.map(String) : [];
  } catch {
    return [];
  }
}

export async function runMissingClauseCheck(
  documentId: number,
  analysisId: number,
  documentType: string | null,
  aiMissingHints: string[] = [],
): Promise<StructuredMissingClause[]> {
  const db = getDb();
  const type = normalizeDocType(documentType);
  const typeVariants = type === 'nda' ? ['nda', 'non_disclosure'] : [type];

  const templates = (await db.select().from(requiredClausesTemplates)).filter((t) =>
    typeVariants.includes(t.documentType),
  );

  const clauseRows = await db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysisId}`);
  const corpus = clauseRows.map((c) => `${c.clauseTitle || ''} ${c.originalText || ''}`).join('\n').toLowerCase();

  const likelyMissing: typeof templates = [];
  const likelyPresent: Array<{ template: typeof templates[0]; clauseId: number | null }> = [];

  for (const t of templates) {
    const kws = parseKeywords(t.detectionKeywords);
    const hit = kws.some((kw) => kw && corpus.includes(kw.toLowerCase()));
    if (hit) {
      const related = clauseRows.find((c) =>
        kws.some((kw) => `${c.clauseTitle || ''} ${c.originalText || ''}`.toLowerCase().includes(kw.toLowerCase())),
      );
      likelyPresent.push({ template: t, clauseId: related?.id ?? null });
    } else {
      likelyMissing.push(t);
    }
  }

  let structured: StructuredMissingClause[] = likelyMissing.map((t) => ({
    name: t.clauseName,
    importance: t.importance,
    why_needed: t.whyNeeded,
    is_confirmed_missing: true,
    is_incomplete: false,
    related_clause_id: null,
  }));

  // Merge AI string hints not already covered
  for (const hint of aiMissingHints) {
    if (!hint) continue;
    if (structured.some((s) => s.name.toLowerCase() === hint.toLowerCase())) continue;
    if (templates.some((t) => t.clauseName.toLowerCase() === hint.toLowerCase())) continue;
    structured.push({
      name: hint,
      importance: 'recommended',
      why_needed: 'Identified by AI as typically expected for this document type.',
      is_confirmed_missing: true,
      is_incomplete: false,
      related_clause_id: null,
    });
  }

  try {
    const { response } = await callWithFallback({
      systemPrompt: `You verify missing and incomplete legal clauses. Return ONLY JSON:
{"missing":[{"name":string,"importance":"critical|recommended|optional","why_needed":string,"is_confirmed_missing":true}],
"incomplete":[{"name":string,"importance":string,"why_needed":string,"related_clause_id":number|null,"is_incomplete":true}]}
Use the required list as the source of truth. Mark incomplete when a topic is mentioned but key details are vague or missing.`,
      userPrompt: JSON.stringify({
        documentType: type,
        required: templates.map((t) => ({
          name: t.clauseName,
          importance: t.importance,
          why_needed: t.whyNeeded,
        })),
        keywordMissing: likelyMissing.map((t) => t.clauseName),
        keywordPresent: likelyPresent.map((p) => ({ name: p.template.clauseName, clauseId: p.clauseId })),
        clauses: clauseRows.map((c) => ({
          id: c.id,
          title: c.clauseTitle,
          text: (c.originalText || '').slice(0, 400),
        })),
      }),
      temperature: 0.2,
      expectJson: true,
    }, { task: 'analysis' });

    const parsed = typeof response.text === 'string' ? parseAiResponse(response.text) : response.text;
    const missing = Array.isArray((parsed as { missing?: unknown }).missing)
      ? (parsed as { missing: StructuredMissingClause[] }).missing
      : [];
    const incomplete = Array.isArray((parsed as { incomplete?: unknown }).incomplete)
      ? (parsed as { incomplete: StructuredMissingClause[] }).incomplete
      : [];

    if (missing.length > 0 || incomplete.length > 0) {
      const byName = new Map<string, StructuredMissingClause>();
      for (const m of structured) byName.set(m.name.toLowerCase(), m);
      for (const m of missing) {
        if (!m?.name) continue;
        byName.set(m.name.toLowerCase(), {
          name: m.name,
          importance: m.importance || 'recommended',
          why_needed: m.why_needed || '',
          is_confirmed_missing: true,
          is_incomplete: false,
          related_clause_id: null,
        });
      }
      for (const m of incomplete) {
        if (!m?.name) continue;
        byName.set(`incomplete:${m.name.toLowerCase()}`, {
          name: m.name,
          importance: m.importance || 'recommended',
          why_needed: m.why_needed || 'Clause appears present but is incomplete or vague.',
          is_confirmed_missing: false,
          is_incomplete: true,
          related_clause_id: m.related_clause_id ?? null,
        });
      }
      structured = [...byName.values()];
    }
  } catch (err) {
    console.error('Missing clause AI check failed:', err instanceof Error ? err.message : err);
  }

  await db.execute(sql`UPDATE ${analysisResults} SET missing_clauses = ${JSON.stringify(structured)} WHERE id = ${analysisId}`);
  persistNow();
  return structured;
}
