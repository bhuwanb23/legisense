import { createWorker, Worker } from 'tesseract.js';
import { convertToJpeg } from './imageProcessor';

export interface OcrWord {
  text: string;
  confidence: number;
}

export interface OcrResult {
  text: string;
  confidence: number;
  rotation: number;
  words: OcrWord[];
  languageUsed: string;
}

let worker: Worker | null = null;
let currentLanguage: string = 'eng';

// Tesseract worker thread failures (e.g. corrupt image) otherwise surface as an
// uncaught exception inside a MessagePort callback and kill the whole process.
// Capture them here and reject the calling promise instead.
let workerError: Error | null = null;

function onWorkerError(err: unknown): void {
  workerError = err instanceof Error ? err : new Error(String(err));
  // A failed worker should not be reused — terminate it so the next call
  // spawns a fresh one.
  const dead = worker;
  worker = null;
  currentLanguage = '';
  dead?.terminate().catch(() => {});
}

async function getWorker(language?: string): Promise<Worker> {
  const lang = language || 'eng';
  if (worker && currentLanguage !== lang) {
    try {
      await worker.reinitialize(lang);
      currentLanguage = lang;
    } catch {
      await worker.terminate();
      worker = null;
    }
  }
  if (!worker) {
    // A fresh worker must not inherit a stale error from the previous one
    // (e.g. a corrupt image failing one job would otherwise poison the next).
    workerError = null;
    try {
      worker = await createWorker(lang, 1, { errorHandler: onWorkerError });
      currentLanguage = lang;
    } catch {
      worker = await createWorker('eng', 1, { errorHandler: onWorkerError });
      currentLanguage = 'eng';
    }
  }
  return worker;
}

export function clearWorkerError(): void {
  workerError = null;
}

/** Read-and-clear the worker error flag (avoids TS narrowing on the module var). */
function consumeWorkerError(): Error | null {
  const err = workerError;
  workerError = null;
  return err;
}

interface TesseractWord {
  text: string;
  confidence: number;
}

export async function ocrImage(
  buffer: Buffer,
  options?: { language?: string; osd?: boolean }
): Promise<OcrResult> {
  const lang = options?.language || 'eng';
  const w = await getWorker(lang);

  const preErr = consumeWorkerError();
  if (preErr) {
    throw new Error(`OCR worker unavailable: ${preErr.message}`);
  }

  let imageBuffer = buffer;
  const header = buffer.subarray(0, 4).toString('hex').toUpperCase();
  const isHeic = header.startsWith('000000') || header.startsWith('667479');

  if (isHeic) {
    try {
      imageBuffer = await convertToJpeg(buffer);
    } catch {
      imageBuffer = buffer;
    }
  }

  const recognizeOptions: Record<string, unknown> = {};
  if (options?.osd) {
    recognizeOptions.rotateAuto = true;
  }

  let data: { text: string; confidence: number; blocks?: unknown; rotateRadians?: unknown };
  try {
    const result = await w.recognize(imageBuffer, recognizeOptions);
    data = result.data;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    // Recover for the next call even if the worker errored mid-job.
    const dead = worker;
    worker = null;
    currentLanguage = '';
    dead?.terminate().catch(() => {});
    throw new Error(`OCR failed: ${message}`);
  }

  const postErr = consumeWorkerError();
  if (postErr) {
    const dead = worker;
    worker = null;
    currentLanguage = '';
    dead?.terminate().catch(() => {});
    throw new Error(`OCR failed: ${postErr.message}`);
  }

  const words: OcrWord[] = [];
  const blocks = (data.blocks ?? []) as Array<{
    paragraphs?: Array<{ lines?: Array<{ words?: unknown }> }>;
  }>;
  for (const block of blocks) {
    if (block.paragraphs) {
      for (const para of block.paragraphs) {
        if (para.lines) {
          for (const line of para.lines) {
            if (line.words) {
              for (const word of line.words as unknown as TesseractWord[]) {
                words.push({ text: word.text, confidence: word.confidence });
              }
            }
          }
        }
      }
    }
  }

  const rotation = data.rotateRadians || 0;
  const rotationDegrees = typeof rotation === 'number' ? Math.round(rotation * 180 / Math.PI) : 0;

  return {
    text: data.text || '',
    confidence: data.confidence || 0,
    rotation: rotationDegrees,
    words,
    languageUsed: lang,
  };
}

export async function ocrPdf(buffer: Buffer): Promise<string> {
  const w = await getWorker('eng');
  const { data } = await w.recognize(buffer, { pdfTitle: 'document' });
  return data.text || '';
}

export async function isImage(buffer: Buffer): Promise<boolean> {
  if (buffer.length < 4) return false;
  const header = buffer.subarray(0, 4).toString('hex').toUpperCase();
  return (
    header.startsWith('89504E47') ||
    header.startsWith('FFD8FF') ||
    header.startsWith('474946') ||
    header.startsWith('424D') ||
    header.startsWith('000000') ||
    header.startsWith('667479')
  );
}

export async function terminateOcr(): Promise<void> {
  if (worker) {
    await worker.terminate();
    worker = null;
  }
}

export function parseLanguagePreference(lang: string): string {
  if (!lang || lang === 'en' || lang === 'eng') return 'eng';

  const langMap: Record<string, string> = {
    en: 'eng',
    es: 'spa',
    fr: 'fra',
    de: 'deu',
    it: 'ita',
    pt: 'por',
    nl: 'nld',
    ja: 'jpn',
    ko: 'kor',
    zh: 'chi_sim',
    zhs: 'chi_sim',
    zht: 'chi_tra',
    ar: 'ara',
    ru: 'rus',
    hi: 'hin',
    bn: 'ben',
    pa: 'pan',
    ta: 'tam',
    te: 'tel',
    mr: 'mar',
    gu: 'guj',
    kn: 'kan',
    ml: 'mal',
    or: 'ori',
    as: 'asm',
    ne: 'nep',
    si: 'sin',
    th: 'tha',
    vi: 'vie',
    id: 'ind',
    ms: 'msa',
    tl: 'tgl',
    tr: 'tur',
    pl: 'pol',
    cs: 'ces',
    ro: 'ron',
    hu: 'hun',
    sv: 'swe',
    da: 'dan',
    fi: 'fin',
    nb: 'nor',
    el: 'ell',
    he: 'heb',
    ur: 'urd',
  };

  return langMap[lang.toLowerCase()] || 'eng';
}

export function buildLanguageString(preferredLanguage: string, extraLanguages?: string): string {
  const primary = parseLanguagePreference(preferredLanguage);
  if (!extraLanguages) return primary;

  const extras = extraLanguages
    .split(/[,+]/)
    .map((l) => l.trim())
    .filter(Boolean)
    .map((l) => parseLanguagePreference(l))
    .filter((l) => l !== primary);

  extras.unshift(primary);
  return [...new Set(extras)].join('+');
}
