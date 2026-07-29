export type ProviderName = 'openrouter' | 'gemini' | 'openai';

export interface AiRequest {
  systemPrompt: string;
  userPrompt: string;
  model?: string;
  maxTokens?: number;
  temperature?: number;
}

export interface AiUsage {
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
}

export interface AiResponse {
  text: string;
  usage: AiUsage;
  model: string;
  provider: ProviderName;
}

export type AiTask = 'analysis' | 'rewrite' | 'chat' | 'classification';

export interface AiContext {
  pageCount?: number;
  language?: string;
  task?: AiTask;
}

export interface AiProvider {
  readonly name: ProviderName;
  generate(request: AiRequest): Promise<AiResponse>;
  isAvailable(): boolean;
}
