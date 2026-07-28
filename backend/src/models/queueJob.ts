import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';

export const queueJobs = sqliteTable('queue_jobs', {
  id: text('id').primaryKey(),
  documentId: integer('document_id').notNull(),
  userId: integer('user_id').notNull(),
  status: text('status').notNull().default('pending'),
  priority: integer('priority').notNull().default(0),
  retryCount: integer('retry_count').notNull().default(0),
  maxRetries: integer('max_retries').notNull().default(3),
  timeoutMs: integer('timeout_ms').notNull().default(300000),
  error: text('error'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
  startedAt: text('started_at'),
  completedAt: text('completed_at'),
});

export type QueueJob = typeof queueJobs.$inferSelect;
