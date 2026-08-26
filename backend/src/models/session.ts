import { text, integer, pgTable, serial, boolean } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './user';

export const sessions = pgTable('sessions', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').notNull().references(() => users.id),
  refreshToken: text('refresh_token').notNull().unique(),
  deviceInfo: text('device_info'),
  ipAddress: text('ip_address'),
  expiresAt: text('expires_at').notNull(),
  isRevoked: boolean('is_revoked').notNull().default(false),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
});

export type Session = typeof sessions.$inferSelect;
export type NewSession = typeof sessions.$inferInsert;
