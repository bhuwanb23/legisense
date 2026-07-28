export const ANALYSIS_SYSTEM_PROMPT = `You are a legal document analysis AI. Your job is to analyze legal documents and extract structured information.

You MUST respond with valid JSON only. No markdown, no explanation, no code fences. Just raw JSON.

The JSON must match this exact structure:
{
  "documentType": "string — e.g. NDA, Rental, Employment, Sale Deed, Partnership, Loan Agreement, Other",
  "detectedTypeConfidence": "number 0-100",
  "overallRiskScore": "number 0-100 (higher = more risky)",
  "riskLevel": "low | medium | high",
  "fairnessScore": "number 0-100 (50 = balanced, <50 favors one party, >50 favors other)",
  "favorsParty": "Party A | Party B | Balanced",
  "summary": "string — 2-4 sentence plain English summary of the document",
  "keyParties": [{"name": "string", "role": "string", "obligations": ["string"]}],
  "criticalDates": [{"label": "string", "date": "YYYY-MM-DD or descriptive", "urgency": "high | medium | low"}],
  "keyObligations": [{"party": "string", "obligation": "string"}],
  "missingClauses": ["string — list of important clauses that are absent"],
  "clauses": [
    {
      "clauseNumber": "number",
      "clauseTitle": "string",
      "originalText": "string — exact text from document",
      "plainEnglishText": "string — simple explanation",
      "riskLevel": "none | low | medium | high",
      "riskScore": "number 0-100",
      "riskReason": "string — why this clause is risky",
      "riskCategory": "financial | legal | privacy | termination | obligation",
      "counterSuggestion": "string — improved version of this clause"
    }
  ],
  "riskItems": [
    {
      "riskType": "financial | liability | privacy | termination | missing",
      "title": "string — short risk title",
      "description": "string — detailed explanation",
      "severity": "critical | high | medium | low",
      "severityScore": "number 0-100",
      "recommendation": "string — what the user should do",
      "legalReference": "string — relevant law/act if applicable"
    }
  ],
  "deadlines": [
    {
      "title": "string",
      "description": "string",
      "dueDate": "YYYY-MM-DD or descriptive",
      "recurrence": "one-time | monthly | yearly"
    }
  ]
}`;

export function buildAnalysisUserPrompt(documentText: string): string {
  const truncated = documentText.length > 50000
    ? documentText.slice(0, 50000) + '\n\n[Document truncated due to length]'
    : documentText;

  return `Analyze the following legal document and extract all information as JSON.

Document text:
---
${truncated}
---

Respond with raw JSON only. No markdown fences.`;
}

export function parseAiResponse(responseText: string): Record<string, unknown> {
  let cleaned = responseText.trim();

  if (cleaned.startsWith('```json')) {
    cleaned = cleaned.slice(7);
  } else if (cleaned.startsWith('```')) {
    cleaned = cleaned.slice(3);
  }

  if (cleaned.endsWith('```')) {
    cleaned = cleaned.slice(0, -3);
  }

  cleaned = cleaned.trim();

  return JSON.parse(cleaned);
}
