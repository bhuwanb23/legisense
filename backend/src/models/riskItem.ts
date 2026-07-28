import { sqliteTable, text, integer, real } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { analysisResults } from './analysisResult';
import { clauses } from './clause';

export const riskItems = sqliteTable('risk_items', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  analysisId: integer('analysis_id').notNull().references(() => analysisResults.id),
  clauseId: integer('clause_id').references(() => clauses.id),
  riskType: text('risk_type').notNull(),
  title: text('title').notNull(),
  description: text('description'),
  severity: text('severity').notNull(),
  severityScore: real('severity_score'),
  recommendation: text('recommendation'),
  legalReference: text('legal_reference'),
  jurisdiction: text('jurisdiction'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type RiskItem = typeof riskItems.$inferSelect;
export type NewRiskItem = typeof riskItems.$inferInsert;
