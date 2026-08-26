import { text, integer, pgTable, serial, doublePrecision } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { clauses } from './clause';
import { documents } from './document';
import { analysisResults } from './analysisResult';
import { riskPatterns } from './riskPattern';

export const clauseRiskFlags = pgTable('clause_risk_flags', {
  id: serial('id').primaryKey(),
  clauseId: integer('clause_id').notNull().references(() => clauses.id),
  documentId: integer('document_id').notNull().references(() => documents.id),
  analysisId: integer('analysis_id').notNull().references(() => analysisResults.id),
  patternId: integer('pattern_id').notNull().references(() => riskPatterns.id),
  matchType: text('match_type').notNull(),
  matchConfidence: doublePrecision('match_confidence').notNull().default(80),
  flaggedTextSnippet: text('flagged_text_snippet'),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
});

export type ClauseRiskFlag = typeof clauseRiskFlags.$inferSelect;
export type NewClauseRiskFlag = typeof clauseRiskFlags.$inferInsert;
