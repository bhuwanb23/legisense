import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';

export const requiredClausesTemplates = sqliteTable('required_clauses_templates', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  documentType: text('document_type').notNull(),
  clauseName: text('clause_name').notNull(),
  importance: text('importance').notNull(),
  whyNeeded: text('why_needed').notNull(),
  exampleText: text('example_text'),
  detectionKeywords: text('detection_keywords').notNull().default('[]'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type RequiredClausesTemplate = typeof requiredClausesTemplates.$inferSelect;
export type NewRequiredClausesTemplate = typeof requiredClausesTemplates.$inferInsert;
