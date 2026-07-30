export interface RetrievedClause {
  id: number;
  clauseNumber: number | null;
  clauseTitle: string | null;
  originalText: string;
  plainEnglishText: string | null;
  pageNumber: number | null;
  score: number;
}

const STOP = new Set([
  'a', 'an', 'the', 'and', 'or', 'to', 'of', 'in', 'on', 'for', 'is', 'are', 'was', 'were',
  'be', 'by', 'with', 'as', 'at', 'from', 'that', 'this', 'it', 'i', 'can', 'my', 'me',
  'do', 'does', 'did', 'what', 'when', 'where', 'how', 'if', 'will', 'would', 'should',
]);

export function tokenize(text: string): string[] {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter((t) => t.length > 2 && !STOP.has(t));
}

export function scoreClause(question: string, clause: {
  clauseTitle?: string | null;
  originalText?: string | null;
  plainEnglishText?: string | null;
}): number {
  const qTokens = tokenize(question);
  if (qTokens.length === 0) return 0;
  const hay = `${clause.clauseTitle || ''} ${clause.originalText || ''} ${clause.plainEnglishText || ''}`.toLowerCase();
  let hits = 0;
  for (const t of qTokens) {
    if (hay.includes(t)) hits += 1;
  }
  // Title hits weigh more
  const title = (clause.clauseTitle || '').toLowerCase();
  for (const t of qTokens) {
    if (title.includes(t)) hits += 1.5;
  }
  return hits / qTokens.length;
}

export function retrieveRelevantClauses(
  question: string,
  clauses: Array<{
    id: number;
    clauseNumber: number | null;
    clauseTitle: string | null;
    originalText: string;
    plainEnglishText: string | null;
    pageNumber: number | null;
  }>,
  topK = 5,
  minScore = 0.15,
): RetrievedClause[] {
  const scored = clauses
    .map((c) => ({
      id: c.id,
      clauseNumber: c.clauseNumber,
      clauseTitle: c.clauseTitle,
      originalText: c.originalText,
      plainEnglishText: c.plainEnglishText,
      pageNumber: c.pageNumber,
      score: scoreClause(question, c),
    }))
    .filter((c) => c.score >= minScore)
    .sort((a, b) => b.score - a.score)
    .slice(0, topK);

  return scored;
}

export function chunkRawText(text: string, size = 800): Array<{ title: string; text: string }> {
  const cleaned = (text || '').trim();
  if (!cleaned) return [];
  const chunks: Array<{ title: string; text: string }> = [];
  for (let i = 0; i < cleaned.length; i += size) {
    chunks.push({
      title: `Section ${chunks.length + 1}`,
      text: cleaned.slice(i, i + size),
    });
  }
  return chunks.slice(0, 8);
}
