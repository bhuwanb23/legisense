import { z } from 'zod';

export const listDocumentsSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  status: z.enum(['all', 'pending', 'ocr_processing', 'text_extracted', 'processing', 'analyzed', 'completed', 'failed']).default('all'),
});

export const sourceTypeEnum = z.enum(['file', 'scan', 'paste', 'url']);

const pasteUploadSchema = z.object({
  sourceType: z.literal('paste'),
  text: z.string().min(50, 'Pasted text must be at least 50 characters').max(500000, 'Text too long (max 500KB)'),
  title: z.string().min(1).max(200).optional(),
});

const urlUploadSchema = z.object({
  sourceType: z.literal('url'),
  url: z.string().url('Invalid URL').refine((v) => {
    try { const u = new URL(v); return u.protocol === 'http:' || u.protocol === 'https:'; } catch { return false; }
  }, 'URL must use http:// or https:// protocol'),
  title: z.string().min(1).max(200).optional(),
});

const fileBaseSchema = z.object({
  sourceType: z.enum(['file', 'scan']),
  title: z.string().min(1).max(200).optional(),
});

export const unifiedUploadSchema = z.discriminatedUnion('sourceType', [
  pasteUploadSchema,
  urlUploadSchema,
  fileBaseSchema,
]);

export type UnifiedUploadInput = z.infer<typeof unifiedUploadSchema>;
export type ListDocumentsInput = z.infer<typeof listDocumentsSchema>;
export type PasteTextInput = z.infer<typeof pasteUploadSchema>;
export type ImportUrlInput = z.infer<typeof urlUploadSchema>;
