import { sqliteTable, text, integer, real } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { users } from './user';
import { documents } from './document';

export const analysisResults = sqliteTable('analysis_results', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  documentId: integer('document_id').notNull().unique().references(() => documents.id),
  userId: integer('user_id').notNull().references(() => users.id),
  documentType: text('document_type'),
  detectedTypeConfidence: real('detected_type_confidence'),
  overallRiskScore: real('overall_risk_score'),
  riskLevel: text('risk_level'),
  fairnessScore: real('fairness_score'),
  favorsParty: text('favors_party'),
  summary: text('summary'),
  keyParties: text('key_parties'),
  criticalDates: text('critical_dates'),
  keyObligations: text('key_obligations'),
  missingClauses: text('missing_clauses'),
  jurisdictionFlags: text('jurisdiction_flags'),
  jurisdictionCheckStatus: text('jurisdiction_check_status').default('pending'),
  breachScenarios: text('breach_scenarios'),
  processingTime: real('processing_time'),
  aiModelUsed: text('ai_model_used'),
  analysisLanguage: text('analysis_language'),
  translations: text('translations').default('{}'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type AnalysisResult = typeof analysisResults.$inferSelect;
export type NewAnalysisResult = typeof analysisResults.$inferInsert;
