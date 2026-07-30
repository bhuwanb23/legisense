import OpenAI from 'openai';
import type { AiProvider, AiRequest, AiResponse, ProviderName } from './types';
import { estimateTokens } from './tokenManager';

const BASE_URL = 'https://openrouter.ai/api/v1';
const SITE_URL = process.env.OPENROUTER_SITE_URL || '';
const SITE_NAME = process.env.OPENROUTER_SITE_NAME || 'LegiSense';

let client: OpenAI | null = null;

function getApiKey(): string {
  return process.env.OPENROUTER_API_KEY || '';
}

function getDefaultModel(): string {
  return process.env.OPENROUTER_MODEL || 'openrouter/free';
}

function getClient(): OpenAI {
  if (!client) {
    const key = getApiKey();
    if (!key) throw new Error('OPENROUTER_API_KEY is not set');
    client = new OpenAI({
      apiKey: key,
      baseURL: BASE_URL,
    });
  }
  return client;
}

export const openRouterProvider: AiProvider = {
  name: 'openrouter' as ProviderName,

  isAvailable(): boolean {
    return Boolean(getApiKey());
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
      max_tokens: request.maxTokens,
      temperature: request.temperature ?? 0.3,
      ...(SITE_URL ? { headers: { 'HTTP-Referer': SITE_URL, 'X-Title': SITE_NAME } } : {}),
    });

    const choice = response.choices?.[0];
    if (!choice?.message?.content) {
      throw new Error('OpenRouter returned empty response');
    }

    const text = choice.message.content;
    if (!text.includes('{') && /safety|blocked|content filter|refused/i.test(text)) {
      throw new Error(`OpenRouter returned a non-JSON safety response: ${text.slice(0, 120)}`);
    }
    const output = response.usage;

    return {
      text,
      usage: {
        inputTokens: output?.prompt_tokens || estimatedInput,
        outputTokens: output?.completion_tokens || estimateTokens(text),
        totalTokens: (output?.prompt_tokens || estimatedInput) + (output?.completion_tokens || estimateTokens(text)),
      },
      model: response.model || model,
      provider: 'openrouter',
    };
  },
};
