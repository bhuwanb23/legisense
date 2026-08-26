import { text, integer, pgTable, serial, boolean } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './user';
import { documents } from './document';

export const shareLinks = pgTable('share_links', {
  id: serial('id').primaryKey(),
  documentId: integer('document_id').notNull().references(() => documents.id),
  userId: integer('user_id').notNull().references(() => users.id),
  token: text('token').notNull().unique(),
  isActive: boolean('is_active').notNull().default(true),
  views: integer('views').notNull().default(0),
  expiresAt: text('expires_at'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type ShareLink = typeof shareLinks.$inferSelect;
export type NewShareLink = typeof shareLinks.$inferInsert;
