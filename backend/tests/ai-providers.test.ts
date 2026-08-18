import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { estimateTokens, estimateRequestTokens, estimateResponseTokens } from '../src/services/ai/tokenManager';
import { calculateCost } from '../src/services/ai/costTracker';
import { selectProvider } from '../src/services/ai/providerSelector';
import { geminiProvider } from '../src/services/ai/geminiProvider';
import { openRouterProvider } from '../src/services/ai/openRouterProvider';
import { openAIProvider } from '../src/services/ai/openAIProvider';
import {
  CLAUSE_REWRITE_SYSTEM_PROMPT,
  buildClauseRewritePrompt,
} from '../src/prompts/clauseRewritePrompt';
import {
  CHAT_SYSTEM_PROMPT,
  buildChatUserPrompt,
} from '../src/prompts/chatPrompt';

// ──────────────────────────────────────────────
//  Token Manager
// ──────────────────────────────────────────────
describe('Token Manager', () => {
  it('estimateTokens returns 0 for empty string', () => {
    assert.equal(estimateTokens(''), 0);
  });

  it('estimateTokens uses ~4 chars per token', () => {
    assert.equal(estimateTokens('abcd'), 1);
    assert.equal(estimateTokens('abcdefgh'), 2);
    assert.equal(estimateTokens('a'), 1);
  });

  it('estimateTokens rounds up', () => {
    assert.equal(estimateTokens('abcde'), 2);
  });

  it('estimateRequestTokens combines system + user', () => {
    const total = estimateRequestTokens('system', 'user');
    assert.equal(total, estimateTokens('system') + estimateTokens('user'));
  });

  it('estimateResponseTokens delegates to estimateTokens', () => {
    assert.equal(estimateResponseTokens('hello'), estimateTokens('hello'));
  });
});

// ──────────────────────────────────────────────
//  Cost Tracker
// ──────────────────────────────────────────────
describe('Cost Tracker — calculateCost', () => {
  const baseUsage = { inputTokens: 1_000_000, outputTokens: 1_000_000, totalTokens: 2_000_000 };

  it('calculates Gemini 1.5 Flash cost', () => {
    const cost = calculateCost(baseUsage, 'gemini-1.5-flash', 'gemini');
    assert.equal(cost, 0.375); // $0.075 input + $0.30 output
  });

  it('returns 0 for openrouter/free', () => {
    const cost = calculateCost(baseUsage, 'openrouter/free', 'openrouter');
    assert.equal(cost, 0);
  });

  it('calculates GPT-4o cost', () => {
    const cost = calculateCost(baseUsage, 'gpt-4o', 'openai');
    assert.equal(cost, 12.5); // $2.50 input + $10.00 output
  });

  it('returns 0 for unknown model', () => {
    const cost = calculateCost(baseUsage, 'unknown-model', 'openai');
    assert.equal(cost, 0);
  });

  it('handles zero tokens', () => {
    const cost = calculateCost({ inputTokens: 0, outputTokens: 0, totalTokens: 0 }, 'gemini-1.5-flash', 'gemini');
    assert.equal(cost, 0);
  });

  it('handles partial tokens', () => {
    const usage = { inputTokens: 1000, outputTokens: 500, totalTokens: 1500 };
    const cost = calculateCost(usage, 'gpt-4o', 'openai');
    assert.equal(cost, 0.0075); // (1000/1M)*2.50 + (500/1M)*10 = 0.0025 + 0.005
  });
});

// ──────────────────────────────────────────────
//  Provider Selection
// ──────────────────────────────────────────────
describe('Provider Selection', () => {
  const oldGeminiKey = process.env.GEMINI_API_KEY;
  const oldOpenRouterKey = process.env.OPENROUTER_API_KEY;
  const oldOpenAIKey = process.env.OPENAI_API_KEY;
  const oldOllama = process.env.OLLAMA_ENABLED;

  before(() => {
    process.env.GEMINI_API_KEY = 'test-gemini-key';
    process.env.OPENROUTER_API_KEY = 'test-or-key';
    process.env.OPENAI_API_KEY = 'test-oa-key';
    process.env.OLLAMA_ENABLED = 'false';
  });

  after(() => {
    if (oldGeminiKey) process.env.GEMINI_API_KEY = oldGeminiKey;
    else delete process.env.GEMINI_API_KEY;
    if (oldOpenRouterKey) process.env.OPENROUTER_API_KEY = oldOpenRouterKey;
    else delete process.env.OPENROUTER_API_KEY;
    if (oldOpenAIKey) process.env.OPENAI_API_KEY = oldOpenAIKey;
    else delete process.env.OPENAI_API_KEY;
    if (oldOllama !== undefined) process.env.OLLAMA_ENABLED = oldOllama;
    else delete process.env.OLLAMA_ENABLED;
  });

  it('selects Gemini for analysis when Gemini is configured', () => {
    const provider = selectProvider({ task: 'analysis' });
    assert.ok(provider);
    assert.equal(provider!.name, 'gemini');
  });

  it('selects Gemini when pageCount > 100', () => {
    const provider = selectProvider({ pageCount: 150, task: 'analysis' });
    assert.ok(provider);
    assert.equal(provider!.name, 'gemini');
  });

  it('selects Gemini for non-English language', () => {
    const provider = selectProvider({ language: 'hi', task: 'analysis' });
    assert.ok(provider);
    assert.equal(provider!.name, 'gemini');
  });

  it('selects Gemini for pageCount > 100 even when English', () => {
    const provider = selectProvider({ pageCount: 200, language: 'en', task: 'analysis' });
    assert.ok(provider);
    assert.equal(provider!.name, 'gemini');
  });

  it('selects Gemini for analysis even when pageCount is small', () => {
    const provider = selectProvider({ pageCount: 50, task: 'analysis' });
    assert.ok(provider);
    assert.equal(provider!.name, 'gemini');
  });

  it('selects Gemini for chat even when OpenRouter is available', () => {
    const provider = selectProvider({ task: 'chat' });
    assert.ok(provider);
    assert.equal(provider!.name, 'gemini');
  });

  it('selects Gemini for rewrite', () => {
    const provider = selectProvider({ task: 'rewrite' });
    assert.ok(provider);
    assert.equal(provider!.name, 'gemini');
  });
});

describe('Provider Availability', () => {
  it('geminiProvider isAvailable checks env var', () => {
    const old = process.env.GEMINI_API_KEY;
    process.env.GEMINI_API_KEY = 'some-key';
    assert.ok(geminiProvider.isAvailable());
    delete process.env.GEMINI_API_KEY;
    assert.equal(geminiProvider.isAvailable(), false);
    if (old) process.env.GEMINI_API_KEY = old;
  });

  it('openRouterProvider isAvailable checks env var', () => {
    const old = process.env.OPENROUTER_API_KEY;
    process.env.OPENROUTER_API_KEY = 'some-key';
    assert.ok(openRouterProvider.isAvailable());
    delete process.env.OPENROUTER_API_KEY;
    assert.equal(openRouterProvider.isAvailable(), false);
    if (old) process.env.OPENROUTER_API_KEY = old;
  });

  it('openAIProvider isAvailable checks env var', () => {
    const old = process.env.OPENAI_API_KEY;
    process.env.OPENAI_API_KEY = 'some-key';
    assert.ok(openAIProvider.isAvailable());
    delete process.env.OPENAI_API_KEY;
    assert.equal(openAIProvider.isAvailable(), false);
    if (old) process.env.OPENAI_API_KEY = old;
  });
});

// ──────────────────────────────────────────────
//  Prompt Builder
// ──────────────────────────────────────────────
describe('Prompt Builders', () => {
  it('CLAUSE_REWRITE_SYSTEM_PROMPT returns valid JSON schema instruction', () => {
    assert.ok(CLAUSE_REWRITE_SYSTEM_PROMPT.includes('originalText'));
    assert.ok(CLAUSE_REWRITE_SYSTEM_PROMPT.includes('rewrittenText'));
    assert.ok(CLAUSE_REWRITE_SYSTEM_PROMPT.includes('changes'));
    assert.ok(CLAUSE_REWRITE_SYSTEM_PROMPT.includes('reasoning'));
    assert.ok(CLAUSE_REWRITE_SYSTEM_PROMPT.includes('riskImpact'));
    assert.ok(CLAUSE_REWRITE_SYSTEM_PROMPT.includes('confidence'));
  });

  it('buildClauseRewritePrompt includes clause text', () => {
    const result = buildClauseRewritePrompt('Party A shall pay $1000', 'high');
    assert.ok(result.includes('Party A shall pay $1000'));
    assert.ok(result.includes('high'));
  });

  it('buildClauseRewritePrompt handles no risk level', () => {
    const result = buildClauseRewritePrompt('Simple clause');
    assert.ok(result.includes('Simple clause'));
  });

  it('CHAT_SYSTEM_PROMPT includes key instructions', () => {
    assert.ok(CHAT_SYSTEM_PROMPT.includes('legal document'));
    assert.ok(CHAT_SYSTEM_PROMPT.toLowerCase().includes('plain english'));
  });

  it('buildChatUserPrompt combines document and message', () => {
    const result = buildChatUserPrompt('Doc text here', 'What does this mean?');
    assert.ok(result.includes('Doc text here'));
    assert.ok(result.includes('What does this mean?'));
  });
});

// ──────────────────────────────────────────────
//  Edge cases
// ──────────────────────────────────────────────
describe('Edge Cases', () => {
  it('selectProvider returns null when no keys configured', () => {
    const oldGemini = process.env.GEMINI_API_KEY;
    const oldOR = process.env.OPENROUTER_API_KEY;
    const oldOA = process.env.OPENAI_API_KEY;
    const oldOllama = process.env.OLLAMA_ENABLED;
    delete process.env.GEMINI_API_KEY;
    delete process.env.OPENROUTER_API_KEY;
    delete process.env.OPENAI_API_KEY;
    process.env.OLLAMA_ENABLED = 'false';

    const provider = selectProvider({ task: 'analysis' });
    assert.equal(provider, null);

    if (oldGemini) process.env.GEMINI_API_KEY = oldGemini;
    if (oldOR) process.env.OPENROUTER_API_KEY = oldOR;
    if (oldOA) process.env.OPENAI_API_KEY = oldOA;
    if (oldOllama !== undefined) process.env.OLLAMA_ENABLED = oldOllama;
    else delete process.env.OLLAMA_ENABLED;
  });

  it('estimateTokens handles very long string', () => {
    const long = 'x'.repeat(100_000);
    const tokens = estimateTokens(long);
    assert.equal(tokens, 25_000);
  });
});
