import { text, integer, pgTable, serial, boolean } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  fullName: text('full_name').notNull(),
  email: text('email').notNull().unique(),
  phoneNumber: text('phone_number'),
  passwordHash: text('password_hash'),
  authProvider: text('auth_provider').notNull().default('email'),
  profilePhotoUrl: text('profile_photo_url'),
  profession: text('profession'),
  preferredLanguage: text('preferred_language').notNull().default('en'),
  defaultJurisdiction: text('default_jurisdiction'),
  nickname: text('nickname'),
  preferredDocumentTypes: text('preferred_document_types'),
  oauthSubject: text('oauth_subject'),
  isVerified: boolean('is_verified').notNull().default(false),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: text('created_at').notNull().default(sql`(NOW()::TEXT)`),
  updatedAt: text('updated_at').notNull().default(sql`(NOW()::TEXT)`),
  lastLoginAt: text('last_login_at'),
});

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
