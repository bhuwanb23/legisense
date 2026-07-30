import { GoogleGenerativeAI } from '@google/generative-ai';
import type { AiProvider, AiRequest, AiResponse, ProviderName } from './types';
import { estimateTokens } from './tokenManager';
import { parseAiResponse } from '../../prompts/analysisPrompt';

const DEFAULT_MODEL = 'gemini-2.0-flash';
const DEFAULT_MAX_RETRIES = 3;
const DEFAULT_TIMEOUT_MS = 60_000;

let genAI: GoogleGenerativeAI | null = null;

function getApiKey(): string {
  return process.env.GEMINI_API_KEY || '';
}

function getClient(): GoogleGenerativeAI {
  if (!genAI) {
    const key = getApiKey();
    if (!key) throw new Error('GEMINI_API_KEY is not set');
    genAI = new GoogleGenerativeAI(key);
  }
  return genAI;
}

export function isGeminiConfigured(): boolean {
  return Boolean(process.env.GEMINI_API_KEY);
}

export const geminiProvider: AiProvider = {
  name: 'gemini' as ProviderName,

  isAvailable(): boolean {
    return Boolean(process.env.GEMINI_API_KEY);
  },

  async generate(request: AiRequest): Promise<AiResponse> {
    const client = getClient();
    const modelName = request.model || DEFAULT_MODEL;

    const model = client.getGenerativeModel({
      model: modelName,
      systemInstruction: request.systemPrompt,
    });

    const userPrompt = request.userPrompt;
    const estimatedInput = estimateTokens(request.systemPrompt + userPrompt);

    let lastError: Error | null = null;

    for (let attempt = 0; attempt < DEFAULT_MAX_RETRIES; attempt++) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT_MS);

        const result = await model.generateContent(userPrompt);
        clearTimeout(timeoutId);

        const text = result.response.text();
        if (!text) throw new Error('Gemini returned empty response');

        const parsed = parseAiResponse(text);
        const cleanedText = typeof parsed === 'object' ? JSON.stringify(parsed) : text;
        const outputTokens = estimateTokens(cleanedText);

        return {
          text: cleanedText,
          usage: {
            inputTokens: estimatedInput,
            outputTokens,
            totalTokens: estimatedInput + outputTokens,
          },
          model: modelName,
          provider: 'gemini',
        };
      } catch (err) {
        lastError = err instanceof Error ? err : new Error(String(err));
        if (isRetryable(lastError) && attempt < DEFAULT_MAX_RETRIES - 1) {
          const delay = Math.pow(2, attempt) * 1000;
          await new Promise((r) => setTimeout(r, delay));
          continue;
        }
        throw lastError;
      }
    }

    throw lastError || new Error('Gemini request failed');
  },
};

function isRetryable(err: Error): boolean {
  const msg = err.message.toLowerCase();
  return (
    msg.includes('timeout') ||
    msg.includes('rate limit') ||
    msg.includes('quota') ||
    msg.includes('429') ||
    msg.includes('503') ||
    msg.includes('unavailable') ||
    msg.includes('internal') ||
    msg.includes('network') ||
    msg.includes('socket') ||
    msg.includes('econnreset') ||
    msg.includes('deadline') ||
    msg.includes('abort')
  );
}
