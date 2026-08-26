import { text, integer, pgTable, serial } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

export const glossary = pgTable('glossary', {
  id: serial('id').primaryKey(),
  term: text('term').notNull().unique(),
  definition: text('definition').notNull(),
  category: text('category'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type Glossary = typeof glossary.$inferSelect;
export type NewGlossary = typeof glossary.$inferInsert;