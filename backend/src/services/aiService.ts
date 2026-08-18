import { ANALYSIS_SYSTEM_PROMPT, buildAnalysisUserPrompt } from '../prompts/analysisPrompt';
import { CLAUSE_REWRITE_SYSTEM_PROMPT, buildClauseRewritePrompt } from '../prompts/clauseRewritePrompt';
import { CHAT_SYSTEM_PROMPT, buildChatUserPrompt } from '../prompts/chatPrompt';
import { chunkDocument } from './chunkService';
import { callWithFallback } from './ai';
import { parseAiResponse } from '../prompts/analysisPrompt';
import type { AiAnalysisResult } from './aiServiceTypes';

const CHUNK_THRESHOLD = 8_000;

export type ProgressCallback = (percent: number, stage: string) => void;

export { isGeminiConfigured } from './ai/geminiProvider';
export type { AiAnalysisResult } from './aiServiceTypes';

export interface AnalysisOutput {
  result: AiAnalysisResult;
  usage: {
    provider: string;
    model: string;
    inputTokens: number;
    outputTokens: number;
    totalTokens: number;
  };
  processingTime: number;
}

export async function analyzeDocument(
  text: string,
  context?: { pageCount?: number; language?: string },
  onProgress?: ProgressCallback,
): Promise<AnalysisOutput> {
  const startTime = Date.now();

  if (text.length <= CHUNK_THRESHOLD) {
    onProgress?.(50, 'Analyzing document...');
    const out = await analyzeSingle(text, context);
    onProgress?.(100, 'Analysis complete');
    const processingTime = (Date.now() - startTime) / 1000;
    return { result: out.result, usage: out.usage, processingTime };
  }

  onProgress?.(10, 'Splitting document into chunks...');
  const out = await analyzeInChunks(text, context, onProgress);
  onProgress?.(95, 'Merging results...');
  const processingTime = (Date.now() - startTime) / 1000;
  return { result: out.result, usage: out.usage, processingTime };
}

async function analyzeSingle(
  text: string,
  context?: { pageCount?: number; language?: string },
): Promise<{ result: AiAnalysisResult; usage: { provider: string; model: string; inputTokens: number; outputTokens: number; totalTokens: number } }> {
  const systemPrompt = ANALYSIS_SYSTEM_PROMPT;
  const userPrompt = buildAnalysisUserPrompt(text);

  const { response, providerUsed } = await callWithFallback(
    { systemPrompt, userPrompt, temperature: 0.3, expectJson: true },
    { ...context, task: 'analysis' },
  );

  const parsed = typeof response.text === 'string' ? parseAiResponse(response.text) : response.text;
  const result = validateAndCleanResult(parsed);

  return {
    result,
    usage: {
      provider: providerUsed,
      model: response.model,
      inputTokens: response.usage.inputTokens,
      outputTokens: response.usage.outputTokens,
      totalTokens: response.usage.totalTokens,
    },
  };
}

async function analyzeInChunks(
  fullText: string,
  context?: { pageCount?: number; language?: string },
  onProgress?: ProgressCallback,
): Promise<{ result: AiAnalysisResult; usage: { provider: string; model: string; inputTokens: number; outputTokens: number; totalTokens: number } }> {
  const chunks = chunkDocument(fullText);
  const chunkResults: AiAnalysisResult[] = [];
  let totalInput = 0;
  let totalOutput = 0;
  let lastProvider = '';
  let lastModel = '';

  const chunkRange = 80 / chunks.length;
  let currentProgress = 15;

  for (let i = 0; i < chunks.length; i++) {
    const chunk = chunks[i];
    onProgress?.(currentProgress, `Analyzing chunk ${i + 1} of ${chunks.length}...`);
    const prefix = `[This is chunk ${chunk.index + 1} of a legal document. Extract all findings from this portion. Return the same JSON structure. Portion to analyze:\n\n`;
    const text = prefix + chunk.text;
    const partial = await analyzeSingle(text, context);
    currentProgress += chunkRange;
    chunkResults.push(partial.result);
    totalInput += partial.usage.inputTokens;
    totalOutput += partial.usage.outputTokens;
    lastProvider = partial.usage.provider || lastProvider;
    lastModel = partial.usage.model || lastModel;
  }

  return {
    result: mergeChunkResults(chunkResults, fullText),
    usage: {
      provider: lastProvider,
      model: lastModel,
      inputTokens: totalInput,
      outputTokens: totalOutput,
      totalTokens: totalInput + totalOutput,
    },
  };
}

export async function rewriteClause(
  clauseText: string,
  riskLevel?: string,
  context?: { pageCount?: number; language?: string },
): Promise<string> {
  const systemPrompt = CLAUSE_REWRITE_SYSTEM_PROMPT;
  const userPrompt = buildClauseRewritePrompt(clauseText, riskLevel);

  const { response } = await callWithFallback(
    { systemPrompt, userPrompt, temperature: 0.5, expectJson: true },
    { ...context, task: 'rewrite' },
  );

  return response.text;
}

export async function chatWithDocument(
  documentText: string,
  message: string,
  context?: { pageCount?: number; language?: string },
  history: Array<{ role: string; message: string }> = [],
): Promise<string> {
  const systemPrompt = CHAT_SYSTEM_PROMPT;
  const userPrompt = buildChatUserPrompt(documentText, message, history);

  const { response } = await callWithFallback(
    { systemPrompt, userPrompt, temperature: 0.5 },
    { ...context, task: 'chat' },
  );

  return response.text;
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
  return merged.length > 2000 ? merged.slice(0, 2000) + '...' : merged;
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
