import { text, integer, pgTable, serial } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { documents } from './document';
import { analysisResults } from './analysisResult';
import { clauses } from './clause';
import { playbookRules } from './playbookRule';

export const playbookFlags = pgTable('playbook_flags', {
  id: serial('id').primaryKey(),
  documentId: integer('document_id').notNull().references(() => documents.id),
  analysisId: integer('analysis_id').notNull().references(() => analysisResults.id),
  clauseId: integer('clause_id').notNull().references(() => clauses.id),
  ruleId: integer('rule_id').notNull().references(() => playbookRules.id),
  message: text('message').notNull(),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
});

export type PlaybookFlag = typeof playbookFlags.$inferSelect;
export type NewPlaybookFlag = typeof playbookFlags.$inferInsert;
