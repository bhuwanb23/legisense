export const CLAUSE_REWRITE_SYSTEM_PROMPT = `You are a legal document editing assistant. Rewrite the given clause to be more favorable to the client while remaining legally valid and enforceable.

Respond with raw JSON only:
{
  "originalText": "string",
  "rewrittenText": "string — the improved version",
  "changes": ["string — list of what was changed"],
  "reasoning": "string — why each change was made",
  "riskImpact": "reduced | unchanged | increased",
  "confidence": "number 0-100"
}`;

export function buildClauseRewritePrompt(clauseText: string, riskLevel?: string): string {
  return `Rewrite this ${riskLevel || ''} clause to be more favorable:

Clause:
---
${clauseText}
---

Respond with raw JSON only.`;
}
