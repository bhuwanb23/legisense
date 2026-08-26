import { text, integer, pgTable, serial, boolean } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './user';
import { documents } from './document';

export const notifications = pgTable('notifications', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').notNull().references(() => users.id),
  type: text('type').notNull(),
  title: text('title').notNull(),
  body: text('body'),
  documentId: integer('document_id').references(() => documents.id),
  isRead: boolean('is_read').notNull().default(false),
  actionUrl: text('action_url'),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
});

export type Notification = typeof notifications.$inferSelect;
export type NewNotification = typeof notifications.$inferInsert;
