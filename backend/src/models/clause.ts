import { text, integer, pgTable, serial, boolean, doublePrecision } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { documents } from './document';
import { analysisResults } from './analysisResult';

export const clauses = pgTable('clauses', {
  id: serial('id').primaryKey(),
  documentId: integer('document_id').notNull().references(() => documents.id),
  analysisId: integer('analysis_id').notNull().references(() => analysisResults.id),
  clauseNumber: integer('clause_number'),
  clauseTitle: text('clause_title'),
  originalText: text('original_text').notNull(),
  plainEnglishText: text('plain_english_text'),
  readingLevel: text('reading_level'),
  keyLegalTerms: text('key_legal_terms'),
  riskLevel: text('risk_level'),
  riskScore: doublePrecision('risk_score'),
  riskReason: text('risk_reason'),
  riskCategory: text('risk_category'),
  counterSuggestion: text('counter_suggestion'),
  negotiationTips: text('negotiation_tips'),
  usedCounter: boolean('used_counter').notNull().default(false),
  copiedAt: text('copied_at'),
  isFlagged: boolean('is_flagged').notNull().default(false),
  pageNumber: integer('page_number'),
  partyReferences: text('party_references'),
  startPosition: integer('start_position'),
  endPosition: integer('end_position'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type Clause = typeof clauses.$inferSelect;
export type NewClause = typeof clauses.$inferInsert;
