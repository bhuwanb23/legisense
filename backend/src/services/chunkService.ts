export interface Chunk {
  index: number;
  text: string;
  startOffset: number;
  endOffset: number;
  estimatedTokens: number;
}

export interface ChunkOptions {
  maxChunkSize?: number;
  overlap?: number;
}

const DEFAULT_MAX_CHUNK_SIZE = 8000;
const DEFAULT_OVERLAP = 200;

export function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4);
}

export function chunkDocument(text: string, options: ChunkOptions = {}): Chunk[] {
  const maxChunkSize = options.maxChunkSize ?? DEFAULT_MAX_CHUNK_SIZE;
  const overlap = options.overlap ?? DEFAULT_OVERLAP;

  if (!text) return [];

  if (text.length <= maxChunkSize) {
    return [{
      index: 0,
      text,
      startOffset: 0,
      endOffset: text.length,
      estimatedTokens: estimateTokens(text),
    }];
  }

  const paragraphs = splitIntoParagraphs(text);
  const chunks: Chunk[] = [];
  let currentChunk = '';
  let chunkStart = 0;
  let chunkIndex = 0;

  for (const para of paragraphs) {
    const wouldBeSize = currentChunk.length + para.length + (currentChunk ? 1 : 0);

    if (wouldBeSize > maxChunkSize && currentChunk.length > 0) {
      const endOffset = chunkStart + currentChunk.length;
      chunks.push({
        index: chunkIndex,
        text: currentChunk.trim(),
        startOffset: chunkStart,
        endOffset,
        estimatedTokens: estimateTokens(currentChunk),
      });
      chunkIndex++;

      const overlapText = extractOverlap(currentChunk, overlap);
      currentChunk = overlapText;
      chunkStart = endOffset - overlapText.length;
    }

    if (para.length > maxChunkSize) {
      // Single paragraph exceeds limit — split by sentences
      const sentenceChunks = splitLargeParagraph(para, maxChunkSize, overlap);
      for (const sc of sentenceChunks) {
        chunks.push({
          index: chunkIndex,
          text: sc.text.trim(),
          startOffset: chunkStart + sc.startOffset,
          endOffset: chunkStart + sc.endOffset,
          estimatedTokens: estimateTokens(sc.text),
        });
        chunkIndex++;
      }
      const lastSc = sentenceChunks[sentenceChunks.length - 1];
      currentChunk = extractOverlap(lastSc.text, overlap);
      chunkStart = chunkStart + lastSc.endOffset - currentChunk.length;
    } else {
      if (currentChunk) currentChunk += '\n';
      currentChunk += para;
    }
  }

  // Flush remaining
  if (currentChunk.trim()) {
    chunks.push({
      index: chunkIndex,
      text: currentChunk.trim(),
      startOffset: chunkStart,
      endOffset: chunkStart + currentChunk.length,
      estimatedTokens: estimateTokens(currentChunk),
    });
  }

  return chunks;
}

function splitIntoParagraphs(text: string): string[] {
  return text
    .split(/\n\s*\n/)
    .map((p) => p.trim())
    .filter((p) => p.length > 0);
}

function splitLargeParagraph(text: string, maxSize: number, overlap: number): Chunk[] {
  const sentences = text.match(/[^.!?]+[.!?]+/g) || [text];
  const chunks: Chunk[] = [];
  let current = '';
  let startOffset = 0;

  for (const sentence of sentences) {
    if ((current + sentence).length > maxSize && current.length > 0) {
      const endOffset = startOffset + current.length;
      chunks.push({
        index: chunks.length,
        text: current.trim(),
        startOffset,
        endOffset,
        estimatedTokens: estimateTokens(current),
      });
      const overlapText = extractOverlap(current, overlap);
      current = overlapText;
      startOffset = endOffset - overlapText.length;
    }
    current += sentence;
  }

  if (current.trim()) {
    chunks.push({
      index: chunks.length,
      text: current.trim(),
      startOffset,
      endOffset: startOffset + current.length,
      estimatedTokens: estimateTokens(current),
    });
  }

  // If no real splits or the single chunk is still too large, use character-level splitting
  if (chunks.length === 0 || (chunks.length === 1 && chunks[0].text.length > maxSize)) {
    return splitBySize(text, maxSize, overlap);
  }

  return chunks;
}

function splitBySize(text: string, maxSize: number, overlap: number): Chunk[] {
  const chunks: Chunk[] = [];
  let start = 0;

  while (start < text.length) {
    const end = Math.min(start + maxSize, text.length);
    const chunkText = text.slice(start, end);
    chunks.push({
      index: chunks.length,
      text: chunkText.trim(),
      startOffset: start,
      endOffset: end,
      estimatedTokens: estimateTokens(chunkText),
    });
    if (end >= text.length) break;
    start = end - overlap;
    if (start < 0) start = 0;
  }

  return chunks;
}

function extractOverlap(text: string, overlapSize: number): string {
  if (overlapSize <= 0 || text.length === 0) return '';
  const lines = text.split('\n');
  let result = '';
  let size = 0;

  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i];
    if (size + line.length + 1 > overlapSize) break;
    result = (result ? line + '\n' + result : line);
    size += line.length + 1;
  }

  return result || text.slice(-overlapSize);
}
