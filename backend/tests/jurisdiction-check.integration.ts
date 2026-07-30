import dotenv from 'dotenv';
dotenv.config();

import { initDatabase, getDb, closeDatabase, persistNow } from '../src/config/database';
import { sql } from 'drizzle-orm';
import {
  users, documents, analysisResults, clauses, jurisdictions, legalRules,
  jurisdictionFlags, jurisdictionConflicts,
} from '../src/models';
import { seedJurisdictionsAndRules } from '../src/data/seedJurisdictions';
import { runJurisdictionCheck, clauseMatchesKeywords } from '../src/services/jurisdictionCheckService';
import { runConflictDetection } from '../src/services/conflictDetectionService';

async function main() {
  process.env.UPLOAD_DIR = process.env.UPLOAD_DIR || './test-f9-uploads';
  await initDatabase();

  const db = getDb();

  await db.run(sql`CREATE TABLE IF NOT EXISTS jurisdictions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_code TEXT NOT NULL,
    country_name TEXT NOT NULL,
    state_code TEXT,
    state_name TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);
  await db.run(sql`CREATE TABLE IF NOT EXISTS legal_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    jurisdiction_id INTEGER NOT NULL,
    document_type TEXT NOT NULL,
    rule_title TEXT NOT NULL,
    rule_description TEXT NOT NULL,
    rule_type TEXT NOT NULL,
    clause_keywords TEXT NOT NULL DEFAULT '[]',
    legal_reference TEXT,
    severity TEXT NOT NULL DEFAULT 'warning',
    conflicting_jurisdictions TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);
  await db.run(sql`CREATE TABLE IF NOT EXISTS jurisdiction_flags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    analysis_id INTEGER NOT NULL,
    document_id INTEGER NOT NULL,
    clause_id INTEGER,
    rule_id INTEGER NOT NULL,
    flag_type TEXT NOT NULL,
    message TEXT NOT NULL,
    legal_reference TEXT,
    severity TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);
  await db.run(sql`CREATE TABLE IF NOT EXISTS jurisdiction_conflicts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    analysis_id INTEGER NOT NULL,
    document_id INTEGER NOT NULL,
    clause_id INTEGER,
    clause_title TEXT,
    conflict_data TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);
  await db.run(sql`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT,
    auth_provider TEXT NOT NULL DEFAULT 'email',
    preferred_language TEXT NOT NULL DEFAULT 'en',
    default_jurisdiction TEXT,
    is_verified INTEGER NOT NULL DEFAULT 0,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);
  await db.run(sql`CREATE TABLE IF NOT EXISTS documents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    original_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    file_format TEXT NOT NULL,
    source_type TEXT NOT NULL,
    raw_text TEXT,
    country_code TEXT,
    state_code TEXT,
    upload_status TEXT NOT NULL DEFAULT 'uploaded',
    processing_status TEXT NOT NULL DEFAULT 'pending',
    is_deleted INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);
  await db.run(sql`CREATE TABLE IF NOT EXISTS analysis_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id INTEGER NOT NULL UNIQUE,
    user_id INTEGER NOT NULL,
    document_type TEXT,
    jurisdiction_flags TEXT,
    jurisdiction_check_status TEXT DEFAULT 'pending',
    analysis_language TEXT,
    translations TEXT DEFAULT '{}',
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);
  await db.run(sql`CREATE TABLE IF NOT EXISTS clauses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id INTEGER NOT NULL,
    analysis_id INTEGER NOT NULL,
    clause_number INTEGER,
    clause_title TEXT,
    original_text TEXT NOT NULL,
    plain_english_text TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  try { db.run(sql`ALTER TABLE documents ADD COLUMN country_code TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE documents ADD COLUMN state_code TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE analysis_results ADD COLUMN jurisdiction_check_status TEXT DEFAULT 'pending'`); } catch {}

  seedJurisdictionsAndRules();

  const jCount = db.select({ c: sql<number>`count(*)` }).from(jurisdictions).all()[0]?.c ?? 0;
  const rCount = db.select({ c: sql<number>`count(*)` }).from(legalRules).all()[0]?.c ?? 0;
  console.log('jurisdictions=', jCount, 'rules=', rCount);
  if (Number(jCount) < 100) throw new Error('Expected jurisdictions seeded');
  if (Number(rCount) < 20) throw new Error('Expected legal rules seeded');

  db.insert(users).values({
    fullName: 'F9 Tester',
    email: `f9-${Date.now()}@test.com`,
    passwordHash: 'x',
    preferredLanguage: 'en',
    defaultJurisdiction: JSON.stringify({ country: 'IN', state: 'MH', history: [] }),
  }).run();
  const user = db.select().from(users).all().pop()!;

  db.insert(documents).values({
    userId: user.id,
    originalName: 'employment.txt',
    storagePath: '',
    fileFormat: 'txt',
    sourceType: 'paste',
    countryCode: 'IN',
    stateCode: 'MH',
    rawText: 'Employee shall not compete with the Company for 2 years after employment.',
    uploadStatus: 'uploaded',
    processingStatus: 'analyzed',
  }).run();
  const doc = db.select().from(documents).all().pop()!;

  db.insert(analysisResults).values({
    documentId: doc.id,
    userId: user.id,
    documentType: 'employment_contract',
    jurisdictionFlags: '[]',
    jurisdictionCheckStatus: 'pending',
    analysisLanguage: 'en',
    translations: '{}',
  }).run();
  const analysis = db.select().from(analysisResults).all().pop()!;

  db.insert(clauses).values({
    documentId: doc.id,
    analysisId: analysis.id,
    clauseNumber: 1,
    clauseTitle: 'Non-Compete',
    originalText: 'Employee shall not compete with the Company for two years after termination of employment.',
    plainEnglishText: 'You cannot work for competitors for 2 years.',
  }).run();

  const flags = await runJurisdictionCheck(doc.id, analysis.id, 'employment_contract');
  console.log('flags=', flags.length);
  if (flags.length === 0) throw new Error('Expected jurisdiction flags for non-compete');

  await runConflictDetection(doc.id, analysis.id, flags);
  const conflicts = db.select().from(jurisdictionConflicts).where(sql`${jurisdictionConflicts.documentId} = ${doc.id}`).all();
  console.log('conflicts=', conflicts.length);

  const storedFlags = db.select().from(jurisdictionFlags).where(sql`${jurisdictionFlags.documentId} = ${doc.id}`).all();
  console.log('stored flags=', storedFlags.length, storedFlags.map((f) => f.flagType).join(','));

  assertTrue(clauseMatchesKeywords('shall not compete', ['shall not compete']), 'keyword helper');
  assertTrue(storedFlags.some((f) => f.flagType === 'violation' || f.flagType === 'conflict'), 'has violation/conflict flag');

  persistNow();
  closeDatabase();
  console.log('F9/F10 integration smoke passed');
}

function assertTrue(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
