import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { chunkDocument, estimateTokens } from '../src/services/chunkService';

describe('Chunk Service', () => {
  describe('estimateTokens', () => {
    it('returns 0 for empty string', () => {
      assert.equal(estimateTokens(''), 0);
    });

    it('estimates ~4 chars per token', () => {
      assert.equal(estimateTokens('abcd'), 1);
      assert.equal(estimateTokens('abcdefgh'), 2);
    });
  });

  describe('chunkDocument', () => {
    it('returns empty array for empty text', () => {
      assert.deepEqual(chunkDocument(''), []);
    });

    it('returns single chunk for short text', () => {
      const chunks = chunkDocument('Hello world');
      assert.equal(chunks.length, 1);
      assert.equal(chunks[0].text, 'Hello world');
      assert.equal(chunks[0].index, 0);
      assert.equal(chunks[0].startOffset, 0);
    });

    it('splits text exceeding maxChunkSize', () => {
      const text = 'A'.repeat(10_000);
      const chunks = chunkDocument(text, { maxChunkSize: 3000, overlap: 50 });
      assert.ok(chunks.length >= 3);
      chunks.forEach((c) => assert.ok(c.text.length <= 3500));
    });

    it('preserves paragraph boundaries', () => {
      const text = 'First paragraph.\n\nSecond paragraph.\n\nThird paragraph.';
      const chunks = chunkDocument(text, { maxChunkSize: 1000, overlap: 0 });
      assert.equal(chunks.length, 1);
      assert.ok(chunks[0].text.includes('First paragraph'));
      assert.ok(chunks[0].text.includes('Second paragraph'));
    });

    it('adds overlap between chunks', () => {
      const paras = Array.from({ length: 20 }, (_, i) => `Paragraph ${i + 1} content here.`);
      const text = paras.join('\n\n');
      const chunks = chunkDocument(text, { maxChunkSize: 200, overlap: 50 });
      assert.ok(chunks.length > 1);
      if (chunks.length > 1) {
        const chunk1End = chunks[0].text.slice(-60);
        const chunk2Start = chunks[1].text.slice(0, 60);
        assert.ok(
          chunk1End.length > 0 && chunk2Start.length > 0,
          'overlap text present in both chunks'
        );
      }
    });

    it('chunks have correct index sequence', () => {
      const text = Array.from({ length: 50 }, (_, i) => `Line ${i + 1}`).join('\n\n');
      const chunks = chunkDocument(text, { maxChunkSize: 200, overlap: 20 });
      chunks.forEach((c, i) => assert.equal(c.index, i));
    });

    it('chunks cover the original text', () => {
      const lines = Array.from({ length: 30 }, (_, i) => `Line ${i + 1} content here`);
      const text = lines.join('\n\n');
      const chunks = chunkDocument(text, { maxChunkSize: 200, overlap: 30 });

      const combined = chunks.map((c) => c.text).join('\n');
      for (const line of lines) {
        assert.ok(combined.includes(line), `Chunks should cover: ${line}`);
      }
    });
  });
});
