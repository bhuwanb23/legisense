import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';

export const glossary = sqliteTable('glossary', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  term: text('term').notNull().unique(),
  definition: text('definition').notNull(),
  category: text('category'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type Glossary = typeof glossary.$inferSelect;
export type NewGlossary = typeof glossary.$inferInsert;