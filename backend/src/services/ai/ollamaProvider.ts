import OpenAI from 'openai';
import type { AiProvider, AiRequest, AiResponse, ProviderName } from './types';
import { estimateTokens } from './tokenManager';

const DEFAULT_BASE = 'http://127.0.0.1:11434/v1';
const DEFAULT_MODEL = 'gemma4:12b';
const HEALTH_CACHE_MS = 30_000;
const HEALTH_PING_MS = 2_000;
const GENERATE_TIMEOUT_MS = 55_000;

let client: OpenAI | null = null;
let healthCache: { ok: boolean; at: number } | null = null;
let healthInFlight: Promise<boolean> | null = null;

function getBaseUrl(): string {
  return (process.env.OLLAMA_BASE_URL || DEFAULT_BASE).replace(/\/$/, '');
}

function getNativeBaseUrl(): string {
  // OpenAI-compat path is /v1; native tags live on the server root.
  return getBaseUrl().replace(/\/v1$/i, '');
}

function getDefaultModel(): string {
  return process.env.OLLAMA_MODEL || DEFAULT_MODEL;
}

function getClient(): OpenAI {
  if (!client) {
    client = new OpenAI({
      apiKey: process.env.OLLAMA_API_KEY || 'ollama',
      baseURL: getBaseUrl(),
      timeout: GENERATE_TIMEOUT_MS,
    });
  }
  return client;
}

export function isOllamaEnabled(): boolean {
  const flag = (process.env.OLLAMA_ENABLED || 'true').toLowerCase();
  return flag !== '0' && flag !== 'false' && flag !== 'off';
}

export function isOllamaConfigured(): boolean {
  return isOllamaEnabled();
}

/** Test helper: drop the 30s health cache. */
export function resetOllamaHealthCache(): void {
  healthCache = null;
}

async function pingOllama(): Promise<boolean> {
  const url = `${getNativeBaseUrl()}/api/tags`;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), HEALTH_PING_MS);
  try {
    const res = await fetch(url, { signal: controller.signal });
    return res.ok;
  } catch {
    return false;
  } finally {
    clearTimeout(timer);
  }
}

export async function refreshOllamaHealth(force = false): Promise<boolean> {
  if (!isOllamaEnabled()) {
    healthCache = { ok: false, at: Date.now() };
    return false;
  }
  if (!force && healthCache && Date.now() - healthCache.at < HEALTH_CACHE_MS) {
    return healthCache.ok;
  }
  if (healthInFlight) return healthInFlight;
  healthInFlight = pingOllama()
    .then((ok) => {
      healthCache = { ok, at: Date.now() };
      return ok;
    })
    .finally(() => {
      healthInFlight = null;
    });
  return healthInFlight;
}

export const ollamaProvider: AiProvider = {
  name: 'ollama' as ProviderName,

  isAvailable(): boolean {
    if (!isOllamaEnabled()) return false;
    if (healthCache && Date.now() - healthCache.at < HEALTH_CACHE_MS) {
      return healthCache.ok;
    }
    // Unknown health: treat as unavailable so we do not hang on a dead daemon.
    void refreshOllamaHealth();
    return false;
  },

  async generate(request: AiRequest): Promise<AiResponse> {
    const c = getClient();
    const model = request.model || getDefaultModel();
    const estimatedInput = estimateTokens(request.systemPrompt + request.userPrompt);

    const response = await c.chat.completions.create({
      model,
      messages: [
        { role: 'system', content: request.systemPrompt },
        { role: 'user', content: request.userPrompt },
      ],
      max_tokens: request.maxTokens ?? 4096,
      temperature: request.temperature ?? 0.2,
    });

    const choice = response.choices?.[0];
    if (!choice?.message?.content) {
      throw new Error('Ollama returned empty response');
    }

    const text = choice.message.content;
    const output = response.usage;

    return {
      text,
      usage: {
        inputTokens: output?.prompt_tokens || estimatedInput,
        outputTokens: output?.completion_tokens || estimateTokens(text),
        totalTokens:
          (output?.prompt_tokens || estimatedInput) +
          (output?.completion_tokens || estimateTokens(text)),
      },
      model: response.model || model,
      provider: 'ollama',
    };
  },
};
