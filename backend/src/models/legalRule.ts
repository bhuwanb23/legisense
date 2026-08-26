import { text, integer, pgTable, serial } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { jurisdictions } from './jurisdiction';

export const legalRules = pgTable('legal_rules', {
  id: serial('id').primaryKey(),
  jurisdictionId: integer('jurisdiction_id').notNull().references(() => jurisdictions.id),
  documentType: text('document_type').notNull(),
  ruleTitle: text('rule_title').notNull(),
  ruleDescription: text('rule_description').notNull(),
  ruleType: text('rule_type').notNull(),
  clauseKeywords: text('clause_keywords').notNull().default('[]'),
  legalReference: text('legal_reference'),
  severity: text('severity').notNull().default('warning'),
  conflictingJurisdictions: text('conflicting_jurisdictions').notNull().default('[]'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type LegalRule = typeof legalRules.$inferSelect;
export type NewLegalRule = typeof legalRules.$inferInsert;
