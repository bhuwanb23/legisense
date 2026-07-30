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
  deadlineType: text('deadline_type'),
  partyResponsible: text('party_responsible'),
  consequenceIfMissed: text('consequence_if_missed'),
  isRecurring: integer('is_recurring', { mode: 'boolean' }).notNull().default(false),
  parentId: integer('parent_id'),
  reminderSent: integer('reminder_sent', { mode: 'boolean' }).notNull().default(false),
  reminderDate: text('reminder_date'),
  reminderEnabled: integer('reminder_enabled', { mode: 'boolean' }).notNull().default(true),
  reminderTimes: text('reminder_times').default('[7,3,1]'),
  reminderChannels: text('reminder_channels').default('["push"]'),
  reminderSentDays: text('reminder_sent_days').default('[]'),
  isCompleted: integer('is_completed', { mode: 'boolean' }).notNull().default(false),
  isDismissed: integer('is_dismissed', { mode: 'boolean' }).notNull().default(false),
  calendarExported: integer('calendar_exported', { mode: 'boolean' }).notNull().default(false),
  exportedAt: text('exported_at'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type Deadline = typeof deadlines.$inferSelect;
export type NewDeadline = typeof deadlines.$inferInsert;
