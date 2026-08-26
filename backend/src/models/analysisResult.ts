import { text, integer, pgTable, serial, doublePrecision } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './user';
import { documents } from './document';

export const analysisResults = pgTable('analysis_results', {
  id: serial('id').primaryKey(),
  documentId: integer('document_id').notNull().unique().references(() => documents.id),
  userId: integer('user_id').notNull().references(() => users.id),
  documentType: text('document_type'),
  detectedTypeConfidence: doublePrecision('detected_type_confidence'),
  overallRiskScore: doublePrecision('overall_risk_score'),
  riskLevel: text('risk_level'),
  fairnessScore: doublePrecision('fairness_score'),
  favorsParty: text('favors_party'),
  imbalanceReason: text('imbalance_reason'),
  perCategoryFairness: text('per_category_fairness'),
  summary: text('summary'),
  keyParties: text('key_parties'),
  criticalDates: text('critical_dates'),
  keyObligations: text('key_obligations'),
  missingClauses: text('missing_clauses'),
  jurisdictionFlags: text('jurisdiction_flags'),
  jurisdictionCheckStatus: text('jurisdiction_check_status').default('pending'),
  breachScenarios: text('breach_scenarios'),
  processingTime: doublePrecision('processing_time'),
  aiModelUsed: text('ai_model_used'),
  analysisLanguage: text('analysis_language'),
  translations: text('translations').default('{}'),
  counterClausesStatus: text('counter_clauses_status').default('skipped'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type AnalysisResult = typeof analysisResults.$inferSelect;
export type NewAnalysisResult = typeof analysisResults.$inferInsert;
