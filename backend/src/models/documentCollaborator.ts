import { text, integer, pgTable, serial } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { documents } from './document';
import { users } from './user';

export const documentCollaborators = pgTable('document_collaborators', {
  id: serial('id').primaryKey(),
  documentId: integer('document_id').notNull().references(() => documents.id),
  invitedBy: integer('invited_by').notNull().references(() => users.id),
  email: text('email').notNull(),
  userId: integer('user_id').references(() => users.id),
  role: text('role').notNull().default('viewer'),
  token: text('token').notNull().unique(),
  status: text('status').notNull().default('pending'),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
});

export type DocumentCollaborator = typeof documentCollaborators.$inferSelect;
export type NewDocumentCollaborator = typeof documentCollaborators.$inferInsert;
