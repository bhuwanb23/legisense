import { PDFParse } from 'pdf-parse';
import mammoth from 'mammoth';

export type SupportedFormat = 'pdf' | 'docx' | 'txt';

const SUPPORTED_FORMATS: SupportedFormat[] = ['pdf', 'docx', 'txt'];

export function isSupportedFormat(format: string): format is SupportedFormat {
  return SUPPORTED_FORMATS.includes(format as SupportedFormat);
}

export function getUnsupportedFormatMessage(format: string): string {
  if (format === 'doc') {
    return 'Legacy .doc format is not supported. Please convert to .docx and try again.';
  }
  return `File format "${format}" is not supported. Supported formats: ${SUPPORTED_FORMATS.join(', ')}`;
}

export async function extractText(buffer: Buffer, format: string): Promise<string> {
  const fmt = format.toLowerCase();

  if (!isSupportedFormat(fmt)) {
    throw new Error(getUnsupportedFormatMessage(fmt));
  }

  switch (fmt) {
    case 'pdf':
      return extractFromPdf(buffer);
    case 'docx':
      return extractFromDocx(buffer);
    case 'txt':
      return buffer.toString('utf-8');
    default:
      throw new Error(`Unknown format: ${fmt}`);
  }
}

async function extractFromPdf(buffer: Buffer): Promise<string> {
  const parser = new PDFParse({ data: buffer });
  const result = await parser.getText();
  const text = result.text;

  if (!text || text.trim().length === 0) {
    throw new Error('PDF appears to contain no extractable text. It may be a scanned document — try OCR.');
  }

  return text;
}

async function extractFromDocx(buffer: Buffer): Promise<string> {
  const result = await mammoth.extractRawText({ buffer });
  const text = result.value;

  if (!text || text.trim().length === 0) {
    throw new Error('DOCX appears to be empty.');
  }

  if (result.messages.length > 0) {
    console.warn('DOCX extraction warnings:', result.messages);
  }

  return text;
}
