import { text, integer, pgTable, serial, boolean, doublePrecision } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './user';

export const documents = pgTable('documents', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').notNull().references(() => users.id),
  originalName: text('original_name').notNull(),
  storagePath: text('storage_path').notNull(),
  fileFormat: text('file_format').notNull(),
  fileSize: integer('file_size'),
  pageCount: integer('page_count'),
  sourceType: text('source_type').notNull(),
  sourceUrl: text('source_url'),
  rawText: text('raw_text'),
  detectedLanguage: text('detected_language'),
  countryCode: text('country_code'),
  stateCode: text('state_code'),
  detectedType: text('detected_type'),
  detectedTypeConfidence: doublePrecision('detected_type_confidence'),
  needsTypeConfirmation: boolean('needs_type_confirmation').notNull().default(false),
  uploadStatus: text('upload_status').notNull().default('uploading'),
  processingStatus: text('processing_status').notNull().default('pending'),
  isDeleted: boolean('is_deleted').notNull().default(false),
  isFavorite: boolean('is_favorite').notNull().default(false),
  autoDeleteAt: text('auto_delete_at'),
  encryptionIv: text('encryption_iv'),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
  updatedAt: text('updated_at').notNull().default(sql`(NOW()::TEXT)`),
});

export type Document = typeof documents.$inferSelect;
export type NewDocument = typeof documents.$inferInsert;
