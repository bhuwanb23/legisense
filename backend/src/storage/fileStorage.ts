import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

const UPLOAD_DIR = path.resolve(process.env.UPLOAD_DIR || path.join(__dirname, '../../uploads'));
const USE_SUPABASE = process.env.STORAGE_BACKEND === 'supabase';

function ensureUploadDir(): void {
  if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
  }
}

function generateFilename(originalName: string, format: string): string {
  const ext = format === 'docx' ? '.docx' : format === 'pdf' ? '.pdf' : format === 'txt' ? '.txt' : path.extname(originalName).toLowerCase();
  return `${uuidv4()}${ext}`;
}

export async function saveFile(buffer: Buffer, originalName: string, format: string): Promise<string> {
  const filename = generateFilename(originalName, format);

  if (USE_SUPABASE) {
    const { saveFileSupabase } = await import('./supabaseStorage');
    await saveFileSupabase(buffer, filename);
  } else {
    ensureUploadDir();
    fs.writeFileSync(path.join(UPLOAD_DIR, filename), buffer);
  }

  return filename;
}

export async function readFile(storagePath: string): Promise<Buffer> {
  if (USE_SUPABASE) {
    const { readFileSupabase } = await import('./supabaseStorage');
    return readFileSupabase(storagePath);
  }

  const fullPath = path.join(UPLOAD_DIR, storagePath);
  if (!fs.existsSync(fullPath)) {
    throw new Error(`File not found: ${storagePath}`);
  }
  return fs.readFileSync(fullPath);
}

export async function deleteFile(storagePath: string): Promise<void> {
  if (USE_SUPABASE) {
    const { deleteFileSupabase } = await import('./supabaseStorage');
    return deleteFileSupabase(storagePath);
  }

  const fullPath = path.join(UPLOAD_DIR, storagePath);
  if (fs.existsSync(fullPath)) {
    fs.unlinkSync(fullPath);
  }
}

export function getUploadDir(): string {
  return UPLOAD_DIR;
}
