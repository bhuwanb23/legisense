import { z } from 'zod';
import { getValidTypes } from '../data/documentTypes';

export const ClassifyOutputSchema = z.object({
  type: z.string().min(1),
  type_label: z.string().min(1),
  confidence: z.number().min(0).max(100),
  sub_type: z.string(),
  icon: z.string(),
});

export type ClassifyOutput = z.infer<typeof ClassifyOutputSchema>;

const VALID_TYPES_JSON = JSON.stringify(getValidTypes());

export const CLASSIFY_SYSTEM_PROMPT = `You are a legal document classifier. Your job is to identify what type of legal document is being analyzed.

Return ONLY valid JSON with this exact structure:
{
  "type": "one of the supported types listed below",
  "type_label": "human-readable name of the document type",
  "confidence": 0-100 number indicating how sure you are,
  "sub_type": "more specific sub-type if identifiable, or empty string",
  "icon": "a simple icon name representing this document type"
}

Supported types: ${VALID_TYPES_JSON}

Rules:
- Read the beginning of the document carefully to identify its purpose.
- Choose the SINGLE best matching type from the supported list.
- Set confidence based on how clear the evidence is: 90-100 for obvious matches, 70-89 for likely matches, 50-69 for partial matches, below 50 if guessing.
- If the document doesn't clearly match any type, use "unknown" with low confidence.
- Respond with raw JSON only. No markdown. No explanation.`;

export function buildClassifyUserPrompt(text: string): string {
  const preview = text.slice(0, 2000);
  return `Classify this legal document based on its beginning:

---
${preview}
---

Return the JSON classification only.`;
}

export function parseClassifyResponse(responseText: string): Record<string, unknown> {
  let cleaned = responseText.trim();
  if (cleaned.startsWith('```json')) cleaned = cleaned.slice(7);
  else if (cleaned.startsWith('```')) cleaned = cleaned.slice(3);
  if (cleaned.endsWith('```')) cleaned = cleaned.slice(0, -3);
  const jsonStart = cleaned.indexOf('{');
  const jsonEnd = cleaned.lastIndexOf('}');
  if (jsonStart !== -1 && jsonEnd !== -1 && jsonEnd > jsonStart) {
    cleaned = cleaned.slice(jsonStart, jsonEnd + 1);
  }
  cleaned = cleaned.trim();
  return JSON.parse(cleaned);
}
