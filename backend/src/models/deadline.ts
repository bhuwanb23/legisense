import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { documents } from './document';
import { users } from './user';

export const deadlines = sqliteTable('deadlines', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  documentId: integer('document_id').notNull().references(() => documents.id),
  userId: integer('user_id').notNull().references(() => users.id),
  title: text('title').notNull(),
  description: text('description'),
  dueDate: text('due_date').notNull(),
  recurrence: text('recurrence'),
  urgencyLevel: text('urgency_level'),
  reminderSent: integer('reminder_sent', { mode: 'boolean' }).notNull().default(false),
  reminderDate: text('reminder_date'),
  isCompleted: integer('is_completed', { mode: 'boolean' }).notNull().default(false),
  isDismissed: integer('is_dismissed', { mode: 'boolean' }).notNull().default(false),
  calendarExported: integer('calendar_exported', { mode: 'boolean' }).notNull().default(false),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type Deadline = typeof deadlines.$inferSelect;
export type NewDeadline = typeof deadlines.$inferInsert;
