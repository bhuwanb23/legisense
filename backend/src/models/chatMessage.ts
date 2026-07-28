import { sqliteTable, text, integer, real } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { documents } from './document';
import { users } from './user';

export const chatMessages = sqliteTable('chat_messages', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  documentId: integer('document_id').notNull().references(() => documents.id),
  userId: integer('user_id').notNull().references(() => users.id),
  sessionId: text('session_id').notNull(),
  role: text('role').notNull(),
  message: text('message').notNull(),
  citedClauseIds: text('cited_clause_ids'),
  citedPages: text('cited_pages'),
  tokensUsed: integer('tokens_used'),
  responseTime: real('response_time'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type ChatMessage = typeof chatMessages.$inferSelect;
export type NewChatMessage = typeof chatMessages.$inferInsert;
