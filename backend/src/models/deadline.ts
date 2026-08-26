import { text, integer, pgTable, serial, boolean } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { documents } from './document';
import { users } from './user';

export const deadlines = pgTable('deadlines', {
  id: serial('id').primaryKey(),
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
  isRecurring: boolean('is_recurring').notNull().default(false),
  parentId: integer('parent_id'),
  reminderSent: boolean('reminder_sent').notNull().default(false),
  reminderDate: text('reminder_date'),
  reminderEnabled: boolean('reminder_enabled').notNull().default(true),
  reminderTimes: text('reminder_times').default('[7,3,1]'),
  reminderChannels: text('reminder_channels').default('["push"]'),
  reminderSentDays: text('reminder_sent_days').default('[]'),
  isCompleted: boolean('is_completed').notNull().default(false),
  isDismissed: boolean('is_dismissed').notNull().default(false),
  calendarExported: boolean('calendar_exported').notNull().default(false),
  exportedAt: text('exported_at'),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
});

export type Deadline = typeof deadlines.$inferSelect;
export type NewDeadline = typeof deadlines.$inferInsert;
