import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { encryptBuffer, decryptBuffer, isEncryptionConfigured } from '../services/encryptionService';

const UPLOAD_DIR = path.resolve(process.env.UPLOAD_DIR || path.join(__dirname, '../../uploads'));

function ensureUploadDir(): void {
  if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
  }
}

function generateFilename(originalName: string, format: string): string {
  const ext = path.extname(originalName).toLowerCase() || `.${format}`;
  return `${uuidv4()}${ext}`;
}

function shouldEncrypt(): boolean {
  return isEncryptionConfigured();
}

export async function saveFile(buffer: Buffer, originalName: string, format: string): Promise<string> {
  const filename = generateFilename(originalName, format);

  let data = buffer;
  if (shouldEncrypt()) {
    const { encrypted, iv } = encryptBuffer(buffer);
    data = Buffer.concat([iv, encrypted]);
  }

  ensureUploadDir();
  fs.writeFileSync(path.join(UPLOAD_DIR, filename), data);

  return filename;
}

export async function readFile(storagePath: string): Promise<Buffer> {
  const fullPath = path.join(UPLOAD_DIR, storagePath);
  if (!fs.existsSync(fullPath)) {
    throw new Error(`File not found: ${storagePath}`);
  }

  const data = fs.readFileSync(fullPath);

  if (shouldEncrypt()) {
    const iv = data.subarray(0, 12);
    const encrypted = data.subarray(12);
    return decryptBuffer(encrypted, iv);
  }

  return data;
}

export async function deleteFile(storagePath: string): Promise<void> {
  const fullPath = path.join(UPLOAD_DIR, storagePath);
  if (fs.existsSync(fullPath)) {
    fs.unlinkSync(fullPath);
  }
}

export function getUploadDir(): string {
  return UPLOAD_DIR;
}
