import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';

export const users = sqliteTable('users', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  fullName: text('full_name').notNull(),
  email: text('email').notNull().unique(),
  phoneNumber: text('phone_number'),
  passwordHash: text('password_hash'),
  authProvider: text('auth_provider').notNull().default('email'),
  profilePhotoUrl: text('profile_photo_url'),
  profession: text('profession'),
  preferredLanguage: text('preferred_language').notNull().default('en'),
  defaultJurisdiction: text('default_jurisdiction'),
  isVerified: integer('is_verified', { mode: 'boolean' }).notNull().default(false),
  isActive: integer('is_active', { mode: 'boolean' }).notNull().default(true),
  createdAt: text('created_at').notNull().default(sql`(datetime('now'))`),
  updatedAt: text('updated_at').notNull().default(sql`(datetime('now'))`),
  lastLoginAt: text('last_login_at'),
});

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
