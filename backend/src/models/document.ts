import { sqliteTable, text, integer, real } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { users } from './user';

export const documents = sqliteTable('documents', {
  id: integer('id').primaryKey({ autoIncrement: true }),
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
  detectedTypeConfidence: real('detected_type_confidence'),
  needsTypeConfirmation: integer('needs_type_confirmation', { mode: 'boolean' }).notNull().default(false),
  uploadStatus: text('upload_status').notNull().default('uploading'),
  processingStatus: text('processing_status').notNull().default('pending'),
  isDeleted: integer('is_deleted', { mode: 'boolean' }).notNull().default(false),
  isFavorite: integer('is_favorite', { mode: 'boolean' }).notNull().default(false),
  autoDeleteAt: text('auto_delete_at'),
  encryptionIv: text('encryption_iv'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
  updatedAt: text('updated_at').notNull().default(sql`(datetime('now'))`),
});

export type Document = typeof documents.$inferSelect;
export type NewDocument = typeof documents.$inferInsert;
