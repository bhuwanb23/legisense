import { text, integer, pgTable, serial } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

export const requiredClausesTemplates = pgTable('required_clauses_templates', {
  id: serial('id').primaryKey(),
  documentType: text('document_type').notNull(),
  clauseName: text('clause_name').notNull(),
  importance: text('importance').notNull(),
  whyNeeded: text('why_needed').notNull(),
  exampleText: text('example_text'),
  detectionKeywords: text('detection_keywords').notNull().default('[]'),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
});

export type RequiredClausesTemplate = typeof requiredClausesTemplates.$inferSelect;
export type NewRequiredClausesTemplate = typeof requiredClausesTemplates.$inferInsert;
