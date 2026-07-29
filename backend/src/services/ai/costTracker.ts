import type { ProviderName, AiUsage } from './types';

interface RateCard {
  inputPer1M: number;
  outputPer1M: number;
}

const RATES: Record<string, RateCard> = {
  'gemini-1.5-flash': { inputPer1M: 0.075, outputPer1M: 0.30 },
  'openrouter/free': { inputPer1M: 0, outputPer1M: 0 },
  'gpt-4o': { inputPer1M: 2.50, outputPer1M: 10.00 },
};

export function calculateCost(usage: AiUsage, model: string, provider: ProviderName): number {
  const key = model.toLowerCase();
  const rate = RATES[key];
  if (!rate) return 0;

  const inputCost = (usage.inputTokens / 1_000_000) * rate.inputPer1M;
  const outputCost = (usage.outputTokens / 1_000_000) * rate.outputPer1M;
  return Math.round((inputCost + outputCost) * 1000000) / 1000000;
}

export async function logAiUsage(
  userId: number,
  documentId: number | undefined,
  provider: ProviderName,
  model: string,
  usage: AiUsage,
  processingTime: number,
): Promise<void> {
  const { getDb, persistNow } = await import('../../config/database');
  const { usageLogs } = await import('../../models');

  const cost = calculateCost(usage, model, provider);

  getDb().insert(usageLogs).values({
    userId,
    action: `ai:${provider}`,
    documentId,
    tokensConsumed: usage.totalTokens,
    processingTime,
    provider,
    model,
    cost,
    inputTokens: usage.inputTokens,
    outputTokens: usage.outputTokens,
  }).run();

  persistNow();
}
