import { sqliteTable, text, integer, real } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';

export const riskPatterns = sqliteTable('risk_patterns', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  patternName: text('pattern_name').notNull(),
  patternCategory: text('pattern_category').notNull(),
  severity: text('severity').notNull(),
  triggerKeywords: text('trigger_keywords').notNull().default('[]'),
  explanation: text('explanation').notNull(),
  recommendation: text('recommendation').notNull(),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type RiskPattern = typeof riskPatterns.$inferSelect;
export type NewRiskPattern = typeof riskPatterns.$inferInsert;
