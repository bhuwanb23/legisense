import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { users } from './user';
import { documents } from './document';

export const notifications = sqliteTable('notifications', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  userId: integer('user_id').notNull().references(() => users.id),
  type: text('type').notNull(),
  title: text('title').notNull(),
  body: text('body'),
  documentId: integer('document_id').references(() => documents.id),
  isRead: integer('is_read', { mode: 'boolean' }).notNull().default(false),
  actionUrl: text('action_url'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type Notification = typeof notifications.$inferSelect;
export type NewNotification = typeof notifications.$inferInsert;
