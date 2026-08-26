import { text, integer, pgTable, serial } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './user';
import { documents } from './document';
import { clauses } from './clause';

export const clauseNotes = pgTable('clause_notes', {
  id: serial('id').primaryKey(),
  clauseId: integer('clause_id').notNull().references(() => clauses.id),
  documentId: integer('document_id').notNull().references(() => documents.id),
  userId: integer('user_id').notNull().references(() => users.id),
  note: text('note').notNull(),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
  updatedAt: text('updated_at').notNull().default(sql`(datetime('now'))`),
});

export type ClauseNote = typeof clauseNotes.$inferSelect;
export type NewClauseNote = typeof clauseNotes.$inferInsert;
