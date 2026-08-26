import { text, integer, pgTable, serial, doublePrecision } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './user';
import { documents } from './document';

export const usageLogs = pgTable('usage_logs', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').notNull().references(() => users.id),
  action: text('action').notNull(),
  documentId: integer('document_id').references(() => documents.id),
  tokensConsumed: integer('tokens_consumed'),
  processingTime: doublePrecision('processing_time'),
  provider: text('provider'),
  model: text('model'),
  cost: doublePrecision('cost'),
  inputTokens: integer('input_tokens'),
  outputTokens: integer('output_tokens'),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
});

export type UsageLog = typeof usageLogs.$inferSelect;
export type NewUsageLog = typeof usageLogs.$inferInsert;
