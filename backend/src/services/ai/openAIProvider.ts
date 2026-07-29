import OpenAI from 'openai';
import type { AiProvider, AiRequest, AiResponse, ProviderName } from './types';
import { estimateTokens } from './tokenManager';

const DEFAULT_MODEL = 'gpt-4o-mini';

let client: OpenAI | null = null;

function getApiKey(): string {
  return process.env.OPENAI_API_KEY || '';
}

function getClient(): OpenAI {
  if (!client) {
    const key = getApiKey();
    if (!key) throw new Error('OPENAI_API_KEY is not set');
    client = new OpenAI({ apiKey: key });
  }
  return client;
}

export const openAIProvider: AiProvider = {
  name: 'openai' as ProviderName,

  isAvailable(): boolean {
    return Boolean(getApiKey());
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
    });

    const choice = response.choices?.[0];
    if (!choice?.message?.content) {
      throw new Error('OpenAI returned empty response');
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
      provider: 'openai',
    };
  },
};
