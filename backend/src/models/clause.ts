import { sqliteTable, text, integer, real } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { documents } from './document';
import { analysisResults } from './analysisResult';

export const clauses = sqliteTable('clauses', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  documentId: integer('document_id').notNull().references(() => documents.id),
  analysisId: integer('analysis_id').notNull().references(() => analysisResults.id),
  clauseNumber: integer('clause_number'),
  clauseTitle: text('clause_title'),
  originalText: text('original_text').notNull(),
  plainEnglishText: text('plain_english_text'),
  readingLevel: text('reading_level'),
  keyLegalTerms: text('key_legal_terms'),
  riskLevel: text('risk_level'),
  riskScore: real('risk_score'),
  riskReason: text('risk_reason'),
  riskCategory: text('risk_category'),
  counterSuggestion: text('counter_suggestion'),
  isFlagged: integer('is_flagged', { mode: 'boolean' }).notNull().default(false),
  pageNumber: integer('page_number'),
  startPosition: integer('start_position'),
  endPosition: integer('end_position'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type Clause = typeof clauses.$inferSelect;
export type NewClause = typeof clauses.$inferInsert;
