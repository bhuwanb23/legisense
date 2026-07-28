import { GoogleGenerativeAI } from '@google/generative-ai';
import { ANALYSIS_SYSTEM_PROMPT, buildAnalysisUserPrompt, parseAiResponse } from '../prompts/analysisPrompt';
import { chunkDocument, type Chunk } from './chunkService';

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const MODEL_NAME = 'gemini-1.5-flash';
const DEFAULT_MAX_RETRIES = 3;
const DEFAULT_TIMEOUT_MS = 60_000;
const CHUNK_THRESHOLD = 8_000;

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
  if (text.length <= CHUNK_THRESHOLD) {
    return analyzeSingle(text);
  }

  return analyzeInChunks(text);
}

async function analyzeSingle(text: string): Promise<AiAnalysisResult> {
  const response = await callGemini(text);
  return validateAndCleanResult(response);
}

async function analyzeInChunks(fullText: string): Promise<AiAnalysisResult> {
  const chunks = chunkDocument(fullText);
  const chunkResults: AiAnalysisResult[] = [];

  for (const chunk of chunks) {
    const partial = await analyzeChunk(chunk);
    chunkResults.push(partial);
  }

  return mergeChunkResults(chunkResults, fullText);
}

async function analyzeChunk(chunk: Chunk): Promise<AiAnalysisResult> {
  const prefix = `[This is chunk ${chunk.index + 1} of a legal document. Extract all findings from this portion. Return the same JSON structure. Portion to analyze:\n\n`;
  const text = prefix + chunk.text;
  const response = await callGemini(text);
  return validateAndCleanResult(response);
}

async function callGemini(text: string): Promise<Record<string, unknown>> {
  const client = getClient();
  const model = client.getGenerativeModel({
    model: MODEL_NAME,
    systemInstruction: ANALYSIS_SYSTEM_PROMPT,
  });

  const userPrompt = buildAnalysisUserPrompt(text);

  let lastError: Error | null = null;

  for (let attempt = 0; attempt < DEFAULT_MAX_RETRIES; attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT_MS);

      const result = await model.generateContent(userPrompt);
      clearTimeout(timeoutId);

      const responseText = result.response.text();

      if (!responseText) {
        throw new Error('Gemini returned an empty response');
      }

      return parseAiResponse(responseText);
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));

      if (isRetryableError(lastError) && attempt < DEFAULT_MAX_RETRIES - 1) {
        const delay = Math.pow(2, attempt) * 1000;
        await new Promise((r) => setTimeout(r, delay));
        continue;
      }

      throw lastError;
    }
  }

  throw lastError || new Error('AI request failed');
}

function isRetryableError(err: Error): boolean {
  const msg = err.message.toLowerCase();
  return (
    msg.includes('timeout') ||
    msg.includes('rate limit') ||
    msg.includes('quota') ||
    msg.includes('429') ||
    msg.includes('503') ||
    msg.includes('unavailable') ||
    msg.includes('internal') ||
    msg.includes('network') ||
    msg.includes('socket') ||
    msg.includes('econnreset') ||
    msg.includes('deadline')
  );
}

function mergeChunkResults(results: AiAnalysisResult[], fullText: string): AiAnalysisResult {
  const allClauses = results.flatMap((r) => r.clauses);
  const allRisks = results.flatMap((r) => r.riskItems);
  const allDeadlines = results.flatMap((r) => r.deadlines);
  const allParties = results.flatMap((r) => r.keyParties);
  const allDates = results.flatMap((r) => r.criticalDates);
  const allObligations = results.flatMap((r) => r.keyObligations);
  const allMissing = [...new Set(results.flatMap((r) => r.missingClauses))];

  const sorted = [...results].sort((a, b) => (b.overallRiskScore || 0) - (a.overallRiskScore || 0));
  const worst = sorted[0];

  return {
    documentType: worst?.documentType || 'Other',
    detectedTypeConfidence: worst?.detectedTypeConfidence || 0,
    overallRiskScore: worst?.overallRiskScore || 0,
    riskLevel: worst?.riskLevel || 'low',
    fairnessScore: worst?.fairnessScore || 50,
    favorsParty: worst?.favorsParty || 'Balanced',
    summary: generateCombinedSummary(results, fullText),
    keyParties: deduplicateParties(allParties),
    criticalDates: allDates,
    keyObligations: allObligations,
    missingClauses: allMissing,
    clauses: allClauses,
    riskItems: allRisks,
    deadlines: allDeadlines,
  };
}

function generateCombinedSummary(results: AiAnalysisResult[], fullText: string): string {
  const summaries = results.map((r) => r.summary).filter(Boolean);
  if (summaries.length === 0) return 'No summary available.';

  const merged = summaries.join(' ');
  if (merged.length > 2000) return merged.slice(0, 2000) + '...';

  return merged;
}

function deduplicateParties(parties: Array<{ name: string; role: string; obligations: string[] }>) {
  const seen = new Set<string>();
  return parties.filter((p) => {
    const key = p.name.toLowerCase().trim();
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
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
