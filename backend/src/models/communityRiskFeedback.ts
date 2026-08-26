import { text, integer, pgTable, serial } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './user';
import { documents } from './document';
import { clauses } from './clause';
import { riskPatterns } from './riskPattern';

export const communityRiskFeedback = pgTable('community_risk_feedback', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').notNull().references(() => users.id),
  documentId: integer('document_id').notNull().references(() => documents.id),
  clauseId: integer('clause_id').notNull().references(() => clauses.id),
  patternId: integer('pattern_id').references(() => riskPatterns.id),
  feedbackType: text('feedback_type').notNull(),
  note: text('note'),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
});

export type CommunityRiskFeedback = typeof communityRiskFeedback.$inferSelect;
export type NewCommunityRiskFeedback = typeof communityRiskFeedback.$inferInsert;
