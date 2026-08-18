import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { users } from './user';

export const playbookRules = sqliteTable('playbook_rules', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  userId: integer('user_id').notNull().references(() => users.id),
  ruleText: text('rule_text').notNull(),
  category: text('category').notNull().default('general'),
  isActive: integer('is_active', { mode: 'boolean' }).notNull().default(true),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type PlaybookRule = typeof playbookRules.$inferSelect;
export type NewPlaybookRule = typeof playbookRules.$inferInsert;
