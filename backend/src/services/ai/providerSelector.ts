import type { AiProvider, AiRequest, AiResponse, AiContext, ProviderName } from './types';
import { geminiProvider } from './geminiProvider';
import { openRouterProvider } from './openRouterProvider';
import { openAIProvider } from './openAIProvider';
import { ollamaProvider, refreshOllamaHealth } from './ollamaProvider';

type ProviderEntry = { provider: AiProvider; label: string };

const ALL_PROVIDERS: ProviderEntry[] = [
  { provider: ollamaProvider, label: 'Ollama' },
  { provider: geminiProvider, label: 'Gemini' },
  { provider: openRouterProvider, label: 'OpenRouter' },
  { provider: openAIProvider, label: 'OpenAI' },
];

const PER_PROVIDER_TIMEOUT_MS = Number(process.env.AI_CALL_TIMEOUT_MS || 55_000);

function prefersCloud(context?: AiContext): boolean {
  const task = context?.task;
  const language = context?.language;
  return task === 'chat' || task === 'rewrite' || Boolean(language && language !== 'en');
}

function firstCloud(): AiProvider | null {
  if (geminiProvider.isAvailable()) return geminiProvider;
  if (openRouterProvider.isAvailable() && !isUnreliableOpenRouter()) return openRouterProvider;
  if (openAIProvider.isAvailable()) return openAIProvider;
  return null;
}

function isUnreliableOpenRouter(): boolean {
  const model = (process.env.OPENROUTER_MODEL || 'openrouter/free').toLowerCase();
  return model.includes('free') || model === 'openrouter/auto';
}

export function selectProvider(context?: AiContext): AiProvider | null {
  const { pageCount, language, task } = context || {};

  if (prefersCloud(context)) {
    const cloud = firstCloud();
    if (cloud) return cloud;
    if (ollamaProvider.isAvailable()) return ollamaProvider;
    return null;
  }

  if (ollamaProvider.isAvailable()) {
    return ollamaProvider;
  }

  if (pageCount && pageCount > 100 && geminiProvider.isAvailable()) {
    return geminiProvider;
  }

  if (language && language !== 'en' && geminiProvider.isAvailable()) {
    return geminiProvider;
  }

  if (task === 'analysis' && geminiProvider.isAvailable()) {
    return geminiProvider;
  }

  if (openRouterProvider.isAvailable() && !isUnreliableOpenRouter()) {
    return openRouterProvider;
  }

  if (geminiProvider.isAvailable()) {
    return geminiProvider;
  }

  if (openAIProvider.isAvailable()) {
    return openAIProvider;
  }

  return null;
}

export function selectProviderForTokens(estimatedTokens: number): AiProvider | null {
  if (ollamaProvider.isAvailable()) return ollamaProvider;

  if (estimatedTokens <= 100_000) {
    if (openRouterProvider.isAvailable() && !isUnreliableOpenRouter()) return openRouterProvider;
    if (geminiProvider.isAvailable()) return geminiProvider;
    if (openAIProvider.isAvailable()) return openAIProvider;
    return null;
  }

  if (estimatedTokens <= 500_000) {
    if (geminiProvider.isAvailable()) return geminiProvider;
    if (openAIProvider.isAvailable()) return openAIProvider;
    return null;
  }

  return null;
}

export function getProvider(name: ProviderName): AiProvider | undefined {
  return ALL_PROVIDERS.find((p) => p.provider.name === name)?.provider;
}

async function withTimeout<T>(promise: Promise<T>, ms: number, label: string): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      promise,
      new Promise<never>((_, reject) => {
        timer = setTimeout(() => reject(new Error(`${label} timed out after ${ms}ms`)), ms);
      }),
    ]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}

export async function callWithFallback(
  request: AiRequest,
  context?: AiContext,
): Promise<{ response: AiResponse; providerUsed: ProviderName }> {
  await refreshOllamaHealth();

  const primary = selectProvider(context);
  if (!primary) {
    throw new Error(
      'No AI provider available. Start Ollama (OLLAMA_ENABLED=true) or set a cloud API key.',
    );
  }

  const fallbackChain = buildFallbackChain(primary.name, context);

  let lastError: Error | null = null;

  for (const provider of fallbackChain) {
    try {
      const response = await withTimeout(
        provider.generate(request),
        PER_PROVIDER_TIMEOUT_MS,
        provider.name,
      );
      return { response, providerUsed: provider.name };
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));
      console.warn(`[AI] ${provider.name} failed: ${lastError.message}`);
    }
  }

  throw lastError || new Error('All AI providers failed');
}

function buildFallbackChain(primaryName: ProviderName, context?: AiContext): AiProvider[] {
  const chain: AiProvider[] = [];
  const added = new Set<ProviderName>();

  const skipOpenRouter = isUnreliableOpenRouter();
  const primary = ALL_PROVIDERS.find((p) => p.provider.name === primaryName);
  if (primary && primary.provider.isAvailable() && !(primaryName === 'openrouter' && skipOpenRouter)) {
    chain.push(primary.provider);
    added.add(primaryName);
  }

  const cloudFirst = prefersCloud(context);
  const analysisTask = context?.task === 'analysis';
  const rest = analysisTask
    ? [geminiProvider, ollamaProvider, openAIProvider]
    : cloudFirst
      ? [geminiProvider, openRouterProvider, openAIProvider, ollamaProvider]
      : [ollamaProvider, geminiProvider, openRouterProvider, openAIProvider];

  for (const provider of rest) {
    if (provider.name === 'openrouter' && skipOpenRouter) continue;
    if (!added.has(provider.name) && provider.isAvailable()) {
      chain.push(provider);
      added.add(provider.name);
    }
  }

  return chain;
}
