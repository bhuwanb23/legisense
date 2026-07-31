import OpenAI from 'openai';
import type { AiProvider, AiRequest, AiResponse, ProviderName } from './types';
import { estimateTokens } from './tokenManager';

const DEFAULT_BASE = 'http://127.0.0.1:11434/v1';
const DEFAULT_MODEL = 'llama3.2:1b';

let client: OpenAI | null = null;

function getBaseUrl(): string {
  return (process.env.OLLAMA_BASE_URL || DEFAULT_BASE).replace(/\/$/, '');
}

function getDefaultModel(): string {
  return process.env.OLLAMA_MODEL || DEFAULT_MODEL;
}

function getClient(): OpenAI {
  if (!client) {
    client = new OpenAI({
      apiKey: process.env.OLLAMA_API_KEY || 'ollama',
      baseURL: getBaseUrl(),
      timeout: 600_000,
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

export const ollamaProvider: AiProvider = {
  name: 'ollama' as ProviderName,

  isAvailable(): boolean {
    return isOllamaEnabled();
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
