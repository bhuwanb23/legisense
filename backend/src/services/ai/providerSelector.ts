import type { AiProvider, AiRequest, AiResponse, AiContext, ProviderName } from './types';
import { geminiProvider } from './geminiProvider';
import { openRouterProvider } from './openRouterProvider';
import { openAIProvider } from './openAIProvider';
import { ollamaProvider } from './ollamaProvider';

type ProviderEntry = { provider: AiProvider; label: string };

const ALL_PROVIDERS: ProviderEntry[] = [
  { provider: ollamaProvider, label: 'Ollama' },
  { provider: geminiProvider, label: 'Gemini' },
  { provider: openRouterProvider, label: 'OpenRouter' },
  { provider: openAIProvider, label: 'OpenAI' },
];

export function selectProvider(context?: AiContext): AiProvider | null {
  // Local Ollama first for all tasks when enabled (avoids cloud quota).
  if (ollamaProvider.isAvailable()) {
    return ollamaProvider;
  }

  const { pageCount, language, task } = context || {};

  if (pageCount && pageCount > 100 && geminiProvider.isAvailable()) {
    return geminiProvider;
  }

  if (language && language !== 'en' && geminiProvider.isAvailable()) {
    return geminiProvider;
  }

  if (task === 'analysis' && geminiProvider.isAvailable()) {
    return geminiProvider;
  }

  if (openRouterProvider.isAvailable()) {
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
    if (openRouterProvider.isAvailable()) return openRouterProvider;
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

export async function callWithFallback(
  request: AiRequest,
  context?: AiContext,
): Promise<{ response: AiResponse; providerUsed: ProviderName }> {
  const primary = selectProvider(context);
  if (!primary) {
    throw new Error(
      'No AI provider available. Start Ollama (OLLAMA_ENABLED=true) or set a cloud API key.',
    );
  }

  const fallbackChain = buildFallbackChain(primary.name);

  let lastError: Error | null = null;

  for (const provider of fallbackChain) {
    try {
      const response = await provider.generate(request);
      return { response, providerUsed: provider.name };
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));
      console.warn(`[AI] ${provider.name} failed: ${lastError.message}`);
    }
  }

  throw lastError || new Error('All AI providers failed');
}

function buildFallbackChain(primaryName: ProviderName): AiProvider[] {
  const chain: AiProvider[] = [];
  const added = new Set<ProviderName>();

  const primary = ALL_PROVIDERS.find((p) => p.provider.name === primaryName);
  if (primary) {
    chain.push(primary.provider);
    added.add(primaryName);
  }

  for (const entry of ALL_PROVIDERS) {
    if (!added.has(entry.provider.name) && entry.provider.isAvailable()) {
      chain.push(entry.provider);
      added.add(entry.provider.name);
    }
  }

  return chain;
}
