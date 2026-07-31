export const ANALYSIS_SYSTEM_PROMPT = `You are a legal document analysis AI.

CRITICAL: Respond with valid JSON only. No markdown, no commentary, no code fences.

documentType must be one of: NDA, Employment Agreement, Lease Agreement, Loan Agreement, Service Agreement, Sale Deed, Partnership Deed, Power of Attorney, Terms of Service, Privacy Policy, Will, Court Notice, MOU, Other.
Never output phrases like "string — detected document type".
summary must be 4–8 sentences and at least ~350 characters.
plainEnglishText must explain the clause in 2–4 concrete sentences (never "Identifies…").
originalText must be a real quote from the document.
riskReason must explain why the clause matters (never only "Standard clause").
deadlines need real calendar dates only — do not invent dates.
missingClauses must not repeat clauses you already extracted.`;

export function buildAnalysisUserPrompt(documentText: string): string {
  return `Analyze the following legal document and extract all information as JSON.

Document text:
---
${documentText}
---

Respond with raw JSON only. No markdown fences, no explanation. Just JSON.`;
}

export function appendLanguageInstructions(
  systemPrompt: string,
  documentLanguage: string,
  responseLanguage: string,
): string {
  return `${systemPrompt}

LANGUAGE INSTRUCTIONS:
- Document language: ${documentLanguage}
- Respond in: ${responseLanguage}
- Write summary, plainEnglishText, riskReason, recommendations, and other narrative fields in ${responseLanguage}.
- Keep JSON field names in English exactly as specified.
- If legal terms have no direct translation, keep the original term and provide a short explanation in ${responseLanguage}.
- originalText must remain the exact text from the document (do not translate originalText).`;
}

/**
 * Extract and parse a JSON object from messy LLM output (tiny local models).
 * Handles preambles, fences, trailing junk, trailing commas, and light repairs.
 */
export function parseAiResponse(responseText: string): Record<string, unknown> {
  let cleaned = responseText.trim();

  cleaned = cleaned
    .replace(/^User Safety:\s*\w+\s*/gim, '')
    .replace(/^Safety:\s*\w+\s*/gim, '')
    .replace(/^Here(?:'s| is)(?: the)?(?: JSON| analysis| response| translation)[:\s]*/i, '')
    .replace(/^Sure[,!]?\s*/i, '')
    .replace(/^Of course[,!]?\s*/i, '')
    .trim();

  const fence = cleaned.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fence?.[1]) {
    cleaned = fence[1].trim();
  }

  const extracted = extractBalancedObject(cleaned);
  if (!extracted) {
    throw new Error(
      `AI response contained no JSON object: ${cleaned.slice(0, 120)}`,
    );
  }

  const attempts = [
    extracted,
    stripTrailingCommas(extracted),
    softRepairJson(stripTrailingCommas(extracted)),
  ];

  let lastErr: unknown;
  for (const attempt of attempts) {
    try {
      return JSON.parse(attempt) as Record<string, unknown>;
    } catch (err) {
      lastErr = err;
    }
  }

  const msg = lastErr instanceof Error ? lastErr.message : 'invalid structure';
  throw new Error(`Failed to parse AI JSON: ${msg}`);
}

/** Walk characters respecting strings so braces inside strings don't confuse us. */
function extractBalancedObject(text: string): string | null {
  const start = text.indexOf('{');
  if (start === -1) return null;

  let depth = 0;
  let inString = false;
  let escape = false;

  for (let i = start; i < text.length; i++) {
    const ch = text[i];
    if (inString) {
      if (escape) {
        escape = false;
        continue;
      }
      if (ch === '\\') {
        escape = true;
        continue;
      }
      if (ch === '"') inString = false;
      continue;
    }
    if (ch === '"') {
      inString = true;
      continue;
    }
    if (ch === '{') depth++;
    else if (ch === '}') {
      depth--;
      if (depth === 0) return text.slice(start, i + 1);
    }
  }
  return null;
}

function stripTrailingCommas(json: string): string {
  return json.replace(/,\s*([}\]])/g, '$1');
}

/** Best-effort fixes for common tiny-model JSON mistakes. */
function softRepairJson(json: string): string {
  let s = json;
  s = s.replace(/[\u201C\u201D]/g, '"').replace(/[\u2018\u2019]/g, "'");
  // Escape raw control chars inside strings by rebuilding string literals carefully
  let out = '';
  let inString = false;
  let escape = false;
  for (let i = 0; i < s.length; i++) {
    const ch = s[i];
    if (inString) {
      if (escape) {
        out += ch;
        escape = false;
        continue;
      }
      if (ch === '\\') {
        out += ch;
        escape = true;
        continue;
      }
      if (ch === '"') {
        out += ch;
        inString = false;
        continue;
      }
      if (ch === '\n') { out += '\\n'; continue; }
      if (ch === '\r') { out += '\\n'; continue; }
      if (ch === '\t') { out += '\\t'; continue; }
      out += ch;
      continue;
    }
    if (ch === '"') {
      inString = true;
      out += ch;
      continue;
    }
    out += ch;
  }
  return stripTrailingCommas(out);
}

