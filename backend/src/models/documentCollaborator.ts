import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { documents } from './document';
import { users } from './user';

export const documentCollaborators = sqliteTable('document_collaborators', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  documentId: integer('document_id').notNull().references(() => documents.id),
  invitedBy: integer('invited_by').notNull().references(() => users.id),
  email: text('email').notNull(),
  userId: integer('user_id').references(() => users.id),
  role: text('role').notNull().default('viewer'),
  token: text('token').notNull().unique(),
  status: text('status').notNull().default('pending'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type DocumentCollaborator = typeof documentCollaborators.$inferSelect;
export type NewDocumentCollaborator = typeof documentCollaborators.$inferInsert;
