import { text, integer, pgTable, serial } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { analysisResults } from './analysisResult';
import { documents } from './document';
import { clauses } from './clause';

export const jurisdictionConflicts = pgTable('jurisdiction_conflicts', {
  id: serial('id').primaryKey(),
  analysisId: integer('analysis_id').notNull().references(() => analysisResults.id),
  documentId: integer('document_id').notNull().references(() => documents.id),
  clauseId: integer('clause_id').references(() => clauses.id),
  clauseTitle: text('clause_title'),
  conflictData: text('conflict_data').notNull().default('[]'),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
});

export type JurisdictionConflict = typeof jurisdictionConflicts.$inferSelect;
export type NewJurisdictionConflict = typeof jurisdictionConflicts.$inferInsert;
