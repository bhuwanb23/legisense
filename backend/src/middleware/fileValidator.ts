import multer from 'multer';
import { Request, Response, NextFunction } from 'express';
import { InvalidFileTypeError, FileTooLargeError } from '../utils/errors';

const MAX_SIZE = 10 * 1024 * 1024;

const ALLOWED_MIME_TYPES = [
  'application/pdf',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/msword',
  'image/png',
  'image/jpeg',
  'image/jpg',
  'image/webp',
  'text/plain',
];

const ALLOWED_EXTENSIONS = ['.pdf', '.docx', '.doc', '.png', '.jpg', '.jpeg', '.webp', '.txt'];

function getFileExtension(filename: string): string {
  const lastDot = filename.lastIndexOf('.');
  return lastDot === -1 ? '' : filename.slice(lastDot).toLowerCase();
}

const storage = multer.memoryStorage();

export const uploadFile = multer({
  storage,
  limits: { fileSize: MAX_SIZE },
  fileFilter: (_req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    const ext = getFileExtension(file.originalname);

    if (!ALLOWED_EXTENSIONS.includes(ext)) {
      return cb(new InvalidFileTypeError(ALLOWED_EXTENSIONS));
    }

    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      return cb(new InvalidFileTypeError(ALLOWED_MIME_TYPES));
    }

    cb(null, true);
  },
});

export function handleMulterError(
  err: Error,
  _req: Request,
  _res: Response,
  next: NextFunction
): void {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return next(new FileTooLargeError('10MB'));
    }
    return next(err);
  }
  next(err);
}

export const ALLOWED_FILE_CONFIG = {
  maxFileSize: MAX_SIZE,
  maxFileSizeLabel: '10MB',
  allowedMimeTypes: ALLOWED_MIME_TYPES,
  allowedExtensions: ALLOWED_EXTENSIONS,
};
