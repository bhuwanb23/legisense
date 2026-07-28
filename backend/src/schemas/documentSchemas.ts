import { z } from 'zod';

export const listDocumentsSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  status: z.enum(['all', 'pending', 'processing', 'completed', 'failed']).default('all'),
});

export const pasteTextSchema = z.object({
  text: z.string().min(1, 'Text is required').max(500000, 'Text too long (max 500KB)'),
  title: z.string().min(1).max(200).optional(),
});

export const importUrlSchema = z.object({
  url: z.string().url('Invalid URL'),
  title: z.string().min(1).max(200).optional(),
});

export type ListDocumentsInput = z.infer<typeof listDocumentsSchema>;
export type PasteTextInput = z.infer<typeof pasteTextSchema>;
export type ImportUrlInput = z.infer<typeof importUrlSchema>;
