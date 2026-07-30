export const CHAT_SYSTEM_PROMPT = `You are a legal document analysis assistant. You help users understand THEIR document using ONLY the provided clause excerpts.

Rules:
- Answer in plain English based ONLY on the provided clauses/context.
- You MUST end every answer with citations in EXACTLY this format (one or more lines):
  [Clause {number} — {title}] (Page {page or N/A})
- If the answer is not supported by the provided clauses, say:
  "This information is not explicitly stated in the document."
  and do NOT invent citations.
- Never invent clause numbers that are not in the context.
- Be honest about limitations — you are an AI assistant, not a lawyer.
- Keep responses concise.`;

export function buildChatUserPrompt(
  contextBlocks: string,
  message: string,
  history: Array<{ role: string; message: string }> = [],
): string {
  const historyText = history
    .slice(-10)
    .map((m) => `${m.role.toUpperCase()}: ${m.message}`)
    .join('\n');

  return `Relevant document clauses:
---
${contextBlocks}
---

${historyText ? `Recent conversation:\n${historyText}\n\n` : ''}User question: ${message}

Remember: cite clauses exactly as [Clause N — Title] (Page X).`;
}
