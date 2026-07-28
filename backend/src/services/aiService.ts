import { GoogleGenerativeAI } from '@google/generative-ai';
import { ANALYSIS_SYSTEM_PROMPT, buildAnalysisUserPrompt, parseAiResponse } from '../prompts/analysisPrompt';

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const MODEL_NAME = 'gemini-1.5-flash';

let genAI: GoogleGenerativeAI | null = null;

function getClient(): GoogleGenerativeAI {
  if (!genAI) {
    if (!GEMINI_API_KEY) {
      throw new Error('GEMINI_API_KEY is not set. Add it to your .env file.');
    }
    genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
  }
  return genAI;
}

export interface AiAnalysisResult {
  documentType: string;
  detectedTypeConfidence: number;
  overallRiskScore: number;
  riskLevel: string;
  fairnessScore: number;
  favorsParty: string;
  summary: string;
  keyParties: Array<{ name: string; role: string; obligations: string[] }>;
  criticalDates: Array<{ label: string; date: string; urgency: string }>;
  keyObligations: Array<{ party: string; obligation: string }>;
  missingClauses: string[];
  clauses: Array<{
    clauseNumber: number;
    clauseTitle: string;
    originalText: string;
    plainEnglishText: string;
    riskLevel: string;
    riskScore: number;
    riskReason: string;
    riskCategory: string;
    counterSuggestion: string;
  }>;
  riskItems: Array<{
    riskType: string;
    title: string;
    description: string;
    severity: string;
    severityScore: number;
    recommendation: string;
    legalReference: string;
  }>;
  deadlines: Array<{
    title: string;
    description: string;
    dueDate: string;
    recurrence: string;
  }>;
}

export async function analyzeDocument(text: string): Promise<AiAnalysisResult> {
  const client = getClient();
  const model = client.getGenerativeModel({
    model: MODEL_NAME,
    systemInstruction: ANALYSIS_SYSTEM_PROMPT,
  });

  const userPrompt = buildAnalysisUserPrompt(text);

  const result = await model.generateContent(userPrompt);
  const responseText = result.response.text();

  if (!responseText) {
    throw new Error('Gemini returned an empty response');
  }

  const parsed = parseAiResponse(responseText);

  return validateAndCleanResult(parsed);
}

function validateAndCleanResult(data: Record<string, unknown>): AiAnalysisResult {
  return {
    documentType: String(data.documentType || 'Other'),
    detectedTypeConfidence: Number(data.detectedTypeConfidence) || 0,
    overallRiskScore: clamp(Number(data.overallRiskScore) || 0, 0, 100),
    riskLevel: validateRiskLevel(String(data.riskLevel || 'low')),
    fairnessScore: clamp(Number(data.fairnessScore) || 50, 0, 100),
    favorsParty: String(data.favorsParty || 'Balanced'),
    summary: String(data.summary || 'No summary available.'),
    keyParties: Array.isArray(data.keyParties) ? data.keyParties : [],
    criticalDates: Array.isArray(data.criticalDates) ? data.criticalDates : [],
    keyObligations: Array.isArray(data.keyObligations) ? data.keyObligations : [],
    missingClauses: Array.isArray(data.missingClauses) ? data.missingClauses : [],
    clauses: Array.isArray(data.clauses) ? data.clauses : [],
    riskItems: Array.isArray(data.riskItems) ? data.riskItems : [],
    deadlines: Array.isArray(data.deadlines) ? data.deadlines : [],
  };
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function validateRiskLevel(level: string): string {
  const valid = ['low', 'medium', 'high'];
  return valid.includes(level) ? level : 'low';
}

export function isGeminiConfigured(): boolean {
  return Boolean(GEMINI_API_KEY);
}
