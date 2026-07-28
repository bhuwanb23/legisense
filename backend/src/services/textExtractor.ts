import { PDFParse } from 'pdf-parse';
import mammoth from 'mammoth';
import { ocrImage, ocrPdf, isImage } from './ocrService';

export type SupportedFormat = 'pdf' | 'docx' | 'txt' | 'png' | 'jpg' | 'jpeg' | 'gif' | 'bmp';

export interface ExtractionResult {
  text: string;
  method: 'pdf' | 'docx' | 'txt' | 'ocr' | 'ocr_pdf_fallback';
}

const SUPPORTED_FORMATS: SupportedFormat[] = ['pdf', 'docx', 'txt', 'png', 'jpg', 'jpeg', 'gif', 'bmp'];

export function isSupportedFormat(format: string): format is SupportedFormat {
  return SUPPORTED_FORMATS.includes(format as SupportedFormat);
}

export function getUnsupportedFormatMessage(format: string): string {
  if (format === 'doc') {
    return 'Legacy .doc format is not supported. Please convert to .docx and try again.';
  }
  return `File format "${format}" is not supported. Supported formats: ${SUPPORTED_FORMATS.join(', ')}`;
}

export async function extractText(buffer: Buffer, format: string): Promise<ExtractionResult> {
  const fmt = format.toLowerCase() as SupportedFormat;

  if (!isSupportedFormat(fmt)) {
    throw new Error(getUnsupportedFormatMessage(fmt));
  }

  const { text, method } = await extractRaw(buffer, fmt);
  return { text: preprocessText(text), method };
}

async function extractRaw(buffer: Buffer, format: SupportedFormat): Promise<{ text: string; method: ExtractionResult['method'] }> {
  switch (format) {
    case 'pdf':
      return extractFromPdf(buffer);
    case 'docx':
      return extractFromDocx(buffer);
    case 'txt':
      return { text: buffer.toString('utf-8'), method: 'txt' };
    case 'png':
    case 'jpg':
    case 'jpeg':
    case 'gif':
    case 'bmp':
      return { text: await ocrImage(buffer), method: 'ocr' };
    default:
      throw new Error(`Unknown format: ${format}`);
  }
}

async function extractFromPdf(buffer: Buffer): Promise<{ text: string; method: ExtractionResult['method'] }> {
  const parser = new PDFParse({ data: buffer });
  const result = await parser.getText();
  const text = result.text;

  if (!text || text.trim().length === 0) {
    // PDF has no extractable text — try OCR
    const ocrText = await ocrPdf(buffer);
    if (!ocrText || ocrText.trim().length === 0) {
      throw new Error('PDF appears to contain no extractable text and OCR produced no output.');
    }
    return { text: ocrText, method: 'ocr_pdf_fallback' };
  }

  return { text, method: 'pdf' };
}

async function extractFromDocx(buffer: Buffer): Promise<{ text: string; method: ExtractionResult['method'] }> {
  const result = await mammoth.extractRawText({ buffer });
  const text = result.value;

  if (!text || text.trim().length === 0) {
    throw new Error('DOCX appears to be empty.');
  }

  if (result.messages.length > 0) {
    console.warn('DOCX extraction warnings:', result.messages);
  }

  return { text, method: 'docx' };
}

function preprocessText(text: string): string {
  return text
    .replace(/\r\n/g, '\n')
    .replace(/\r/g, '\n')
    .replace(/\t/g, ' ')
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, '')
    .replace(/ {2,}/g, ' ')
    .replace(/\n{4,}/g, '\n\n\n')
    .trim();
}
