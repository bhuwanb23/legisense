export interface ParsedCitation {
  clauseNumber: number;
  title?: string;
  page?: number | null;
  raw: string;
}

export interface CitedClauseDetail {
  clause_id: number;
  clause_number: number | null;
  title: string | null;
  page: number | null;
  snippet: string;
}

/** Matches: [Clause 3 — Title] (Page 2) or [Clause 3 - Title] (Page N/A) or [Clause 3] */
const CITATION_RE =
  /\[Clause\s+(\d+)(?:\.\d+)?(?:\s*[—\-–:]\s*([^\]]+))?\](?:\s*\(\s*Page\s+([^)]+)\))?/gi;

export function parseCitations(responseText: string): ParsedCitation[] {
  const found: ParsedCitation[] = [];
  let match: RegExpExecArray | null;
  const re = new RegExp(CITATION_RE.source, 'gi');
  while ((match = re.exec(responseText)) !== null) {
    const num = Number(match[1]);
    if (!Number.isFinite(num) || !Number.isInteger(num)) continue;
    const pageRaw = (match[3] || '').trim();
    const page = /^\d+$/.test(pageRaw) ? Number(pageRaw) : null;
    found.push({
      clauseNumber: num,
      title: match[2]?.trim(),
      page,
      raw: match[0],
    });
  }
  return found;
}

function toDetail(
  clause: {
    id: number;
    clauseNumber: number | null;
    clauseTitle: string | null;
    originalText: string;
    pageNumber: number | null;
  },
  pageOverride?: number | null,
): CitedClauseDetail {
  return {
    clause_id: clause.id,
    clause_number: clause.clauseNumber,
    title: clause.clauseTitle,
    page: pageOverride ?? clause.pageNumber,
    snippet: (clause.originalText || '').slice(0, 160),
  };
}

export function resolveCitations(
  responseText: string,
  clauses: Array<{
    id: number;
    clauseNumber: number | null;
    clauseTitle: string | null;
    originalText: string;
    pageNumber: number | null;
  }>,
  fallbackClauseIds: number[] = [],
): {
  citedClauses: CitedClauseDetail[];
  citedClauseIds: number[];
  citedPages: Array<number | null>;
  citationConfidence: 'high' | 'low';
} {
  const parsed = parseCitations(responseText);
  const byNumber = new Map<number, typeof clauses[0]>();
  const byId = new Map<number, typeof clauses[0]>();
  for (const c of clauses) {
    if (c.clauseNumber != null) byNumber.set(c.clauseNumber, c);
    byId.set(c.id, c);
  }

  const citedClauses: CitedClauseDetail[] = [];
  const seen = new Set<number>();

  for (const p of parsed) {
    const clause = byNumber.get(p.clauseNumber);
    if (!clause || seen.has(clause.id)) continue;
    seen.add(clause.id);
    citedClauses.push(toDetail(clause, p.page));
  }

  if (citedClauses.length === 0) {
    for (const id of fallbackClauseIds) {
      const clause = byId.get(id);
      if (!clause || seen.has(clause.id)) continue;
      seen.add(clause.id);
      citedClauses.push(toDetail(clause));
    }
  }

  const citationConfidence: 'high' | 'low' =
    parsed.length > 0 && citedClauses.length > 0 ? 'high' : citedClauses.length > 0 ? 'low' : 'low';

  return {
    citedClauses,
    citedClauseIds: citedClauses.map((c) => c.clause_id),
    citedPages: citedClauses.map((c) => c.page),
    citationConfidence,
  };
}
