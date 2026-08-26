import { text, integer, pgTable, serial, doublePrecision } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { analysisResults } from './analysisResult';
import { clauses } from './clause';

export const riskItems = pgTable('risk_items', {
  id: serial('id').primaryKey(),
  analysisId: integer('analysis_id').notNull().references(() => analysisResults.id),
  clauseId: integer('clause_id').references(() => clauses.id),
  riskType: text('risk_type').notNull(),
  title: text('title').notNull(),
  description: text('description'),
  severity: text('severity').notNull(),
  severityScore: doublePrecision('severity_score'),
  recommendation: text('recommendation'),
  legalReference: text('legal_reference'),
  jurisdiction: text('jurisdiction'),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
});

export type RiskItem = typeof riskItems.$inferSelect;
export type NewRiskItem = typeof riskItems.$inferInsert;
