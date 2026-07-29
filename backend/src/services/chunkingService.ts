import { chunkDocument, estimateTokens } from './chunkService';
import type { AnalysisOutput } from '../schemas/analysisSchemas';

const TARGET_TOKENS_PER_CHUNK = 6_000;
const OVERLAP_CHARS = 300;

export interface ChunkInfo {
  index: number;
  text: string;
  estimatedTokens: number;
}

export function chunkText(text: string, targetTokens?: number): ChunkInfo[] {
  const maxTokens = targetTokens ?? TARGET_TOKENS_PER_CHUNK;
  const maxChars = maxTokens * 4;

  const chunks = chunkDocument(text, { maxChunkSize: maxChars, overlap: OVERLAP_CHARS });

  return chunks.map((c) => ({
    index: c.index,
    text: c.text,
    estimatedTokens: c.estimatedTokens,
  }));
}

export function estimateRequestTokens(systemPrompt: string, userPrompt: string): number {
  return estimateTokens(systemPrompt) + estimateTokens(userPrompt);
}

export function estimateTotalRequestTokens(systemPrompt: string, documentText: string): number {
  return estimateTokens(systemPrompt) + estimateTokens(documentText);
}

function deduplicateParties(parties: AnalysisOutput['keyParties']): AnalysisOutput['keyParties'] {
  const seen = new Map<string, AnalysisOutput['keyParties'][number]>();
  for (const p of parties) {
    const key = p.name.toLowerCase().trim();
    const existing = seen.get(key);
    if (existing) {
      existing.obligations = [...new Set([...existing.obligations, ...p.obligations])];
    } else {
      seen.set(key, { ...p, obligations: [...p.obligations] });
    }
  }
  return Array.from(seen.values());
}

export function mergeAnalysisResults(results: AnalysisOutput[]): AnalysisOutput {
  if (results.length === 0) {
    throw new Error('Cannot merge zero analysis results');
  }

  if (results.length === 1) {
    return results[0];
  }

  const allClauses = results.flatMap((r) => r.clauses);
  const allRisks = results.flatMap((r) => r.riskItems);
  const allDeadlines = results.flatMap((r) => r.deadlines);
  const allParties = results.flatMap((r) => r.keyParties);
  const allDates = results.flatMap((r) => r.criticalDates);
  const allObligations = results.flatMap((r) => r.keyObligations);
  const allMissing = [...new Set(results.flatMap((r) => r.missingClauses))];

  const sorted = [...results].sort((a, b) => b.overallRiskScore - a.overallRiskScore);
  const worst = sorted[0];

  const summaries = results.map((r) => r.summary).filter(Boolean);
  const mergedSummary = summaries.length > 0
    ? (summaries.join(' ').length > 2000 ? summaries.join(' ').slice(0, 2000) + '...' : summaries.join(' '))
    : 'No summary available.';

  return {
    documentType: worst.documentType || 'Other',
    detectedTypeConfidence: worst.detectedTypeConfidence || 0,
    overallRiskScore: worst.overallRiskScore || 0,
    riskLevel: worst.riskLevel || 'low',
    fairnessScore: worst.fairnessScore || 50,
    favorsParty: worst.favorsParty || 'Balanced',
    summary: mergedSummary,
    keyParties: deduplicateParties(allParties),
    criticalDates: allDates,
    keyObligations: allObligations,
    missingClauses: allMissing,
    clauses: allClauses,
    riskItems: allRisks,
    deadlines: allDeadlines,
  };
}
