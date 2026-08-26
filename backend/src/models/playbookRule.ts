import { text, integer, pgTable, serial, boolean } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './user';

export const playbookRules = pgTable('playbook_rules', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').notNull().references(() => users.id),
  ruleText: text('rule_text').notNull(),
  category: text('category').notNull().default('general'),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
});

export type PlaybookRule = typeof playbookRules.$inferSelect;
export type NewPlaybookRule = typeof playbookRules.$inferInsert;
