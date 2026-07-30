import dotenv from 'dotenv';
dotenv.config();

import { initDatabase, getDb, closeDatabase, persistNow } from '../src/config/database';
import { sql } from 'drizzle-orm';
import {
  users, documents, analysisResults, clauses, riskPatterns, clauseRiskFlags,
  requiredClausesTemplates, deadlines,
} from '../src/models';
import { seedRiskAndRequiredLibraries } from '../src/data/seedRiskLibraries';
import { expandRecurringDates, saveDeadlinesForDocument, calculateDeadlineUrgency } from '../src/services/deadlineService';

async function main() {
  await initDatabase();
  const db = getDb();

  for (const stmt of [
    `CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, full_name TEXT NOT NULL, email TEXT NOT NULL UNIQUE, password_hash TEXT, auth_provider TEXT NOT NULL DEFAULT 'email', preferred_language TEXT NOT NULL DEFAULT 'en', is_verified INTEGER NOT NULL DEFAULT 0, is_active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL DEFAULT (datetime('now')), updated_at TEXT NOT NULL DEFAULT (datetime('now')))`,
    `CREATE TABLE IF NOT EXISTS documents (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, original_name TEXT NOT NULL, storage_path TEXT NOT NULL, file_format TEXT NOT NULL, source_type TEXT NOT NULL, upload_status TEXT NOT NULL DEFAULT 'uploaded', processing_status TEXT NOT NULL DEFAULT 'pending', is_deleted INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL DEFAULT (datetime('now')), updated_at TEXT NOT NULL DEFAULT (datetime('now')))`,
    `CREATE TABLE IF NOT EXISTS analysis_results (id INTEGER PRIMARY KEY AUTOINCREMENT, document_id INTEGER NOT NULL UNIQUE, user_id INTEGER NOT NULL, document_type TEXT, missing_clauses TEXT, counter_clauses_status TEXT DEFAULT 'skipped', created_at TEXT NOT NULL DEFAULT (datetime('now')))`,
    `CREATE TABLE IF NOT EXISTS clauses (id INTEGER PRIMARY KEY AUTOINCREMENT, document_id INTEGER NOT NULL, analysis_id INTEGER NOT NULL, clause_number INTEGER, clause_title TEXT, original_text TEXT NOT NULL, plain_english_text TEXT, risk_score REAL, risk_level TEXT, is_flagged INTEGER NOT NULL DEFAULT 0, counter_suggestion TEXT, created_at TEXT NOT NULL DEFAULT (datetime('now')))`,
    `CREATE TABLE IF NOT EXISTS risk_patterns (id INTEGER PRIMARY KEY AUTOINCREMENT, pattern_name TEXT NOT NULL, pattern_category TEXT NOT NULL, severity TEXT NOT NULL, trigger_keywords TEXT NOT NULL DEFAULT '[]', explanation TEXT NOT NULL, recommendation TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT (datetime('now')))`,
    `CREATE TABLE IF NOT EXISTS clause_risk_flags (id INTEGER PRIMARY KEY AUTOINCREMENT, clause_id INTEGER NOT NULL, document_id INTEGER NOT NULL, analysis_id INTEGER NOT NULL, pattern_id INTEGER NOT NULL, match_type TEXT NOT NULL, match_confidence REAL NOT NULL DEFAULT 80, flagged_text_snippet TEXT, created_at TEXT NOT NULL DEFAULT (datetime('now')))`,
    `CREATE TABLE IF NOT EXISTS required_clauses_templates (id INTEGER PRIMARY KEY AUTOINCREMENT, document_type TEXT NOT NULL, clause_name TEXT NOT NULL, importance TEXT NOT NULL, why_needed TEXT NOT NULL, example_text TEXT, detection_keywords TEXT NOT NULL DEFAULT '[]', created_at TEXT NOT NULL DEFAULT (datetime('now')))`,
    `CREATE TABLE IF NOT EXISTS deadlines (id INTEGER PRIMARY KEY AUTOINCREMENT, document_id INTEGER NOT NULL, user_id INTEGER NOT NULL, title TEXT NOT NULL, description TEXT, due_date TEXT NOT NULL, recurrence TEXT, urgency_level TEXT, deadline_type TEXT, party_responsible TEXT, consequence_if_missed TEXT, is_recurring INTEGER NOT NULL DEFAULT 0, parent_id INTEGER, is_completed INTEGER NOT NULL DEFAULT 0, is_dismissed INTEGER NOT NULL DEFAULT 0, reminder_sent INTEGER NOT NULL DEFAULT 0, calendar_exported INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL DEFAULT (datetime('now')))`,
  ]) {
    db.run(sql.raw(stmt));
  }

  seedRiskAndRequiredLibraries();

  const pCount = Number(db.select({ c: sql<number>`count(*)` }).from(riskPatterns).all()[0]?.c ?? 0);
  const tCount = Number(db.select({ c: sql<number>`count(*)` }).from(requiredClausesTemplates).all()[0]?.c ?? 0);
  console.log('patterns=', pCount, 'templates=', tCount);
  if (pCount < 50) throw new Error('Expected 50+ patterns');
  if (tCount < 20) throw new Error('Expected templates');

  db.insert(users).values({ fullName: 'F12', email: `f12-${Date.now()}@t.com`, passwordHash: 'x' }).run();
  const user = db.select().from(users).all().pop()!;

  db.insert(documents).values({
    userId: user.id,
    originalName: 'emp.txt',
    storagePath: '',
    fileFormat: 'txt',
    sourceType: 'paste',
    uploadStatus: 'uploaded',
    processingStatus: 'analyzed',
  }).run();
  const doc = db.select().from(documents).all().pop()!;

  db.insert(analysisResults).values({
    documentId: doc.id,
    userId: user.id,
    documentType: 'employment_contract',
    missingClauses: '[]',
    counterClausesStatus: 'pending',
  }).run();
  const analysis = db.select().from(analysisResults).all().pop()!;

  db.insert(clauses).values({
    documentId: doc.id,
    analysisId: analysis.id,
    clauseNumber: 1,
    clauseTitle: 'Liability',
    originalText: 'The Employee liability shall be unlimited under this agreement without any cap.',
    plainEnglishText: 'You can owe unlimited money.',
    riskScore: 85,
    riskLevel: 'high',
  }).run();
  const clause = db.select().from(clauses).all().pop()!;

  // Keyword-only flag without AI
  const patterns = db.select().from(riskPatterns).all();
  let flagged = 0;
  for (const p of patterns) {
    const kws = JSON.parse(p.triggerKeywords) as string[];
    if (kws.some((k) => clause.originalText.toLowerCase().includes(k.toLowerCase()))) {
      db.insert(clauseRiskFlags).values({
        clauseId: clause.id,
        documentId: doc.id,
        analysisId: analysis.id,
        patternId: p.id,
        matchType: 'keyword',
        matchConfidence: 90,
        flaggedTextSnippet: 'liability shall be unlimited',
      }).run();
      flagged++;
    }
  }
  db.run(sql`UPDATE ${clauses} SET is_flagged = 1 WHERE id = ${clause.id}`);
  console.log('keyword flags=', flagged);
  if (flagged < 1) throw new Error('Expected unlimited liability flag');

  saveDeadlinesForDocument(doc.id, user.id, [{
    title: 'Monthly Salary',
    description: 'Pay salary',
    dueDate: '2025-01-01',
    recurrence: 'monthly',
    deadlineType: 'payment',
    partyResponsible: 'Employer',
    isRecurring: true,
  }]);

  const dl = db.select().from(deadlines).where(sql`${deadlines.documentId} = ${doc.id}`).all();
  console.log('deadlines=', dl.length, 'urgency=', dl[0]?.urgencyLevel);
  if (dl.length < 12) throw new Error(`Expected 12 recurring deadlines, got ${dl.length}`);

  persistNow();
  closeDatabase();
  console.log('F12/F15 integration smoke passed');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
