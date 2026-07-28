import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

const UPLOAD_DIR = path.resolve(process.env.UPLOAD_DIR || path.join(__dirname, '../../uploads'));

function ensureUploadDir(): void {
  if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
  }
}

function sanitizeFilename(originalName: string): string {
  const ext = path.extname(originalName).toLowerCase();
  const safeExt = ['.pdf', '.docx', '.doc', '.txt', '.png', '.jpg', '.jpeg', '.webp'].includes(ext)
    ? ext
    : '.bin';
  return `${uuidv4()}${safeExt}`;
}

export function saveFile(buffer: Buffer, originalName: string, format: string): string {
  ensureUploadDir();

  const ext = format === 'docx' ? '.docx' : format === 'pdf' ? '.pdf' : format === 'txt' ? '.txt' : path.extname(originalName).toLowerCase();
  const filename = `${uuidv4()}${ext}`;
  const filePath = path.join(UPLOAD_DIR, filename);

  fs.writeFileSync(filePath, buffer);

  return filename;
}

export function readFile(storagePath: string): Buffer {
  const fullPath = path.join(UPLOAD_DIR, storagePath);

  if (!fs.existsSync(fullPath)) {
    throw new Error(`File not found: ${storagePath}`);
  }

  return fs.readFileSync(fullPath);
}

export function deleteFile(storagePath: string): void {
  const fullPath = path.join(UPLOAD_DIR, storagePath);

  if (fs.existsSync(fullPath)) {
    fs.unlinkSync(fullPath);
  }
}

export function getUploadDir(): string {
  return UPLOAD_DIR;
}
