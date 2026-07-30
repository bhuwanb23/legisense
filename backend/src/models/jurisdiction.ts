import { sqliteTable, text, integer, uniqueIndex } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';

export const jurisdictions = sqliteTable('jurisdictions', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  countryCode: text('country_code').notNull(),
  countryName: text('country_name').notNull(),
  stateCode: text('state_code'),
  stateName: text('state_name'),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
}, (table) => ({
  countryStateIdx: uniqueIndex('idx_jurisdictions_country_state').on(table.countryCode, table.stateCode),
}));

export type Jurisdiction = typeof jurisdictions.$inferSelect;
export type NewJurisdiction = typeof jurisdictions.$inferInsert;
