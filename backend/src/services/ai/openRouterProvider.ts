import OpenAI from 'openai';
import type { AiProvider, AiRequest, AiResponse, ProviderName } from './types';
import { estimateTokens } from './tokenManager';

const API_KEY = process.env.OPENROUTER_API_KEY || '';
const BASE_URL = 'https://openrouter.ai/api/v1';
const DEFAULT_MODEL = process.env.OPENROUTER_MODEL || 'openrouter/free';
const SITE_URL = process.env.OPENROUTER_SITE_URL || '';
const SITE_NAME = process.env.OPENROUTER_SITE_NAME || 'LegiSense';

let client: OpenAI | null = null;

function getClient(): OpenAI {
  if (!client) {
    if (!API_KEY) throw new Error('OPENROUTER_API_KEY is not set');
    client = new OpenAI({
      apiKey: API_KEY,
      baseURL: BASE_URL,
    });
  }
  return client;
}

export const openRouterProvider: AiProvider = {
  name: 'openrouter' as ProviderName,

  isAvailable(): boolean {
    return Boolean(process.env.OPENROUTER_API_KEY);
  },

  async generate(request: AiRequest): Promise<AiResponse> {
    const c = getClient();
    const model = request.model || DEFAULT_MODEL;
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
