import { spawn } from 'child_process';
import { writeFile, unlink, mkdtemp } from 'fs/promises';
import { join, extname } from 'path';
import { tmpdir } from 'os';
import { extractText, type ExtractionResult } from './textExtractor';
import { ocrImage } from './ocrService';
import { convertToJpeg } from './imageProcessor';

export interface DocumentExtractResult {
  text: string;
  method: string;
}

let markitdownChecked = false;
let markitdownAvailable = false;

async function hasMarkitdown(): Promise<boolean> {
  if (markitdownChecked) return markitdownAvailable;
  markitdownChecked = true;
  try {
    await runCommand('markitdown', ['--help'], 8_000);
    markitdownAvailable = true;
    console.log('[extract] MarkItDown CLI available');
  } catch {
    markitdownAvailable = false;
    console.log('[extract] MarkItDown not found — using Node pdf-parse/mammoth/tesseract fallbacks');
  }
  return markitdownAvailable;
}

function runCommand(cmd: string, args: string[], timeoutMs: number): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { shell: true, windowsHide: true });
    let stdout = '';
    let stderr = '';
    const timer = setTimeout(() => {
      child.kill();
      reject(new Error(`${cmd} timed out after ${timeoutMs}ms`));
    }, timeoutMs);

    child.stdout.on('data', (d) => { stdout += d.toString(); });
    child.stderr.on('data', (d) => { stderr += d.toString(); });
    child.on('error', (err) => {
      clearTimeout(timer);
      reject(err);
    });
    child.on('close', (code) => {
      clearTimeout(timer);
      if (code === 0 && stdout.trim()) resolve(stdout.trim());
      else reject(new Error(stderr.trim() || `${cmd} exited with code ${code}`));
    });
  });
}

async function extractWithMarkitdown(buffer: Buffer, format: string): Promise<string> {
  const dir = await mkdtemp(join(tmpdir(), 'legisense-md-'));
  const filePath = join(dir, `doc.${format || 'bin'}`);
  try {
    await writeFile(filePath, buffer);
    const text = await runCommand('markitdown', [filePath], 120_000);
    return text;
  } finally {
    try { await unlink(filePath); } catch { /* ignore */ }
  }
}

const IMAGE_EXTS = new Set(['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'heic', 'heif']);

/**
 * Extract plain text from a stored file buffer. Never sends bytes to an LLM.
 * Prefers MarkItDown CLI when installed; falls back to pdf-parse / mammoth / Tesseract.
 */
export async function extractDocumentText(
  buffer: Buffer,
  format: string,
): Promise<DocumentExtractResult> {
  const fmt = (format || '').toLowerCase().replace(/^\./, '');

  if (IMAGE_EXTS.has(fmt)) {
    let img = buffer;
    if (fmt === 'heic' || fmt === 'heif' || fmt === 'webp') {
      img = await convertToJpeg(buffer);
    }
    const ocr = await ocrImage(img);
    return { text: preprocess(ocr.text), method: 'tesseract' };
  }

  if (await hasMarkitdown()) {
    try {
      const text = await extractWithMarkitdown(buffer, fmt || 'bin');
      if (text.trim().length > 0) {
        return { text: preprocess(text), method: 'markitdown' };
      }
    } catch (err) {
      console.warn('[extract] MarkItDown failed, falling back:', err instanceof Error ? err.message : err);
    }
  }

  const result: ExtractionResult = await extractText(buffer, fmt);
  return { text: result.text, method: result.method };
}

export function extractFormatFromPath(storagePath: string, fileFormat?: string | null): string {
  if (fileFormat) return fileFormat.toLowerCase();
  const ext = extname(storagePath).replace('.', '').toLowerCase();
  return ext || 'txt';
}

function preprocess(text: string): string {
  return text
    .replace(/\r\n/g, '\n')
    .replace(/\r/g, '\n')
    .replace(/\t/g, ' ')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}
