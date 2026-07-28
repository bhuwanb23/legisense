import { sqliteTable, text, integer, real } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { users } from './user';
import { documents } from './document';

export const usageLogs = sqliteTable('usage_logs', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  userId: integer('user_id').notNull().references(() => users.id),
  action: text('action').notNull(),
  documentId: integer('document_id').references(() => documents.id),
  tokensConsumed: integer('tokens_consumed'),
  processingTime: real('processing_time'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type UsageLog = typeof usageLogs.$inferSelect;
export type NewUsageLog = typeof usageLogs.$inferInsert;
