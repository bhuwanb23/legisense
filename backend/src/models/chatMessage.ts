import { text, integer, pgTable, serial, doublePrecision } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { documents } from './document';
import { users } from './user';

export const chatMessages = pgTable('chat_messages', {
  id: serial('id').primaryKey(),
  documentId: integer('document_id').notNull().references(() => documents.id),
  userId: integer('user_id').notNull().references(() => users.id),
  sessionId: text('session_id').notNull(),
  role: text('role').notNull(),
  message: text('message').notNull(),
  citedClauseIds: text('cited_clause_ids'),
  citedPages: text('cited_pages'),
  tokensUsed: integer('tokens_used'),
  responseTime: doublePrecision('response_time'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type ChatMessage = typeof chatMessages.$inferSelect;
export type NewChatMessage = typeof chatMessages.$inferInsert;
