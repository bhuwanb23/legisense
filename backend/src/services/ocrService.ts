import { createWorker, Worker } from 'tesseract.js';

let worker: Worker | null = null;

async function getWorker(): Promise<Worker> {
  if (!worker) {
    worker = await createWorker('eng', 1);
  }
  return worker;
}

export async function ocrImage(buffer: Buffer): Promise<string> {
  const w = await getWorker();
  const { data } = await w.recognize(buffer);
  return data.text || '';
}

export async function ocrPdf(buffer: Buffer): Promise<string> {
  const w = await getWorker();
  const { data } = await w.recognize(buffer, { pdfTitle: 'document' });
  return data.text || '';
}

export async function isImage(buffer: Buffer): Promise<boolean> {
  if (buffer.length < 4) return false;
  const header = buffer.subarray(0, 4).toString('hex').toUpperCase();
  return (
    header.startsWith('89504E47') ||  // PNG
    header.startsWith('FFD8FF') ||    // JPEG
    header.startsWith('474946') ||    // GIF
    header.startsWith('424D')         // BMP
  );
}

export async function terminateOcr(): Promise<void> {
  if (worker) {
    await worker.terminate();
    worker = null;
  }
}
