import { OcrResult, parseLanguagePreference } from './ocrService';

const MISTRAL_API_URL = 'https://api.mistral.ai/v1/ocr';
const MISTRAL_MODEL = 'mistral-ocr-latest';

interface MistralOcrPage {
  index: number;
  markdown: string;
  images: Array<{ id: string; base64?: string }>;
  dimensions?: { width: number; height: number };
}

interface MistralOcrResponse {
  pages: MistralOcrPage[];
  model: string;
  usage_info?: { pages_processed: number };
}

function getApiKey(): string {
  const key = process.env.MISTRAL_API_KEY;
  if (!key) {
    throw new Error('MISTRAL_API_KEY environment variable is not set');
  }
  return key;
}

export async function mistralOcrImage(
  buffer: Buffer,
  options?: { language?: string }
): Promise<OcrResult> {
  const apiKey = getApiKey();
  const base64 = buffer.toString('base64');

  const mimeType = detectMimeType(buffer);
  const dataUri = `data:${mimeType};base64,${base64}`;

  const response = await fetch(MISTRAL_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: MISTRAL_MODEL,
      document: {
        type: 'image_url',
        image_url: dataUri,
      },
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text().catch(() => 'Unknown error');
    throw new Error(`Mistral OCR API error (${response.status}): ${errorBody}`);
  }

  const result = await response.json() as MistralOcrResponse;

  const text = result.pages
    .map((p) => p.markdown)
    .join('\n\n')
    .trim();

  const confidence = result.pages.length > 0 ? 85 : 0;

  const words = text
    .split(/\s+/)
    .filter(Boolean)
    .map((word) => ({
      text: word,
      confidence: 85,
    }));

  const lang = options?.language || 'eng';
  const languageUsed = parseLanguagePreference(lang);

  return {
    text,
    confidence,
    rotation: 0,
    words,
    languageUsed,
  };
}

function detectMimeType(buffer: Buffer): string {
  if (buffer.length < 4) return 'application/octet-stream';
  const header = buffer.subarray(0, 4).toString('hex').toUpperCase();

  if (header.startsWith('89504E47')) return 'image/png';
  if (header.startsWith('FFD8FF')) return 'image/jpeg';
  if (header.startsWith('474946')) return 'image/gif';
  if (header.startsWith('424D')) return 'image/bmp';
  if (header.startsWith('000000') || header.startsWith('667479')) return 'image/heic';
  if (header.startsWith('524946') && buffer.subarray(8, 12).toString() === 'WEBP') return 'image/webp';

  return 'application/octet-stream';
}
