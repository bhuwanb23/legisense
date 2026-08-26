import { text, integer, pgTable, serial } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { analysisResults } from './analysisResult';
import { documents } from './document';
import { clauses } from './clause';
import { legalRules } from './legalRule';

export const jurisdictionFlags = pgTable('jurisdiction_flags', {
  id: serial('id').primaryKey(),
  analysisId: integer('analysis_id').notNull().references(() => analysisResults.id),
  documentId: integer('document_id').notNull().references(() => documents.id),
  clauseId: integer('clause_id').references(() => clauses.id),
  ruleId: integer('rule_id').notNull().references(() => legalRules.id),
  flagType: text('flag_type').notNull(),
  message: text('message').notNull(),
  legalReference: text('legal_reference'),
  severity: text('severity').notNull(),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type JurisdictionFlag = typeof jurisdictionFlags.$inferSelect;
export type NewJurisdictionFlag = typeof jurisdictionFlags.$inferInsert;
