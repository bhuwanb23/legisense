import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { users } from './user';
import { documents } from './document';

export const shareLinks = sqliteTable('share_links', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  documentId: integer('document_id').notNull().references(() => documents.id),
  userId: integer('user_id').notNull().references(() => users.id),
  token: text('token').notNull().unique(),
  isActive: integer('is_active', { mode: 'boolean' }).notNull().default(true),
  views: integer('views').notNull().default(0),
  expiresAt: text('expires_at'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type ShareLink = typeof shareLinks.$inferSelect;
export type NewShareLink = typeof shareLinks.$inferInsert;
