import dotenv from 'dotenv';
dotenv.config();

import { initDatabase, getDb, closeDatabase, persistNow } from '../src/config/database';
import { sql } from 'drizzle-orm';
import { users, documents, clauses, deadlines, chatMessages, analysisResults } from '../src/models';
import { buildIcsCalendar } from '../src/services/icsExportService';
import { resolveCitations } from '../src/services/citationParserService';
import { retrieveRelevantClauses } from '../src/services/chatRetrievalService';
import { daysUntilDue, shouldSendReminder } from '../src/queue/scheduledJobs';

async function main() {
  await initDatabase();
  const db = getDb();

  for (const stmt of [
    `CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, full_name TEXT NOT NULL, email TEXT NOT NULL UNIQUE, password_hash TEXT, auth_provider TEXT NOT NULL DEFAULT 'email', preferred_language TEXT NOT NULL DEFAULT 'en', is_verified INTEGER NOT NULL DEFAULT 0, is_active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL DEFAULT (datetime('now')), updated_at TEXT NOT NULL DEFAULT (datetime('now')))`,
    `CREATE TABLE IF NOT EXISTS documents (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, original_name TEXT NOT NULL, storage_path TEXT NOT NULL, file_format TEXT NOT NULL, source_type TEXT NOT NULL, upload_status TEXT NOT NULL DEFAULT 'uploaded', processing_status TEXT NOT NULL DEFAULT 'pending', is_deleted INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL DEFAULT (datetime('now')), updated_at TEXT NOT NULL DEFAULT (datetime('now')))`,
    `CREATE TABLE IF NOT EXISTS analysis_results (id INTEGER PRIMARY KEY AUTOINCREMENT, document_id INTEGER NOT NULL UNIQUE, user_id INTEGER NOT NULL, document_type TEXT, created_at TEXT NOT NULL DEFAULT (datetime('now')))`,
    `CREATE TABLE IF NOT EXISTS clauses (id INTEGER PRIMARY KEY AUTOINCREMENT, document_id INTEGER NOT NULL, analysis_id INTEGER NOT NULL, clause_number INTEGER, clause_title TEXT, original_text TEXT NOT NULL, plain_english_text TEXT, page_number INTEGER, created_at TEXT NOT NULL DEFAULT (datetime('now')))`,
    `CREATE TABLE IF NOT EXISTS deadlines (id INTEGER PRIMARY KEY AUTOINCREMENT, document_id INTEGER NOT NULL, user_id INTEGER NOT NULL, title TEXT NOT NULL, description TEXT, due_date TEXT NOT NULL, consequence_if_missed TEXT, is_completed INTEGER NOT NULL DEFAULT 0, is_dismissed INTEGER NOT NULL DEFAULT 0, reminder_sent INTEGER NOT NULL DEFAULT 0, reminder_enabled INTEGER NOT NULL DEFAULT 1, reminder_times TEXT DEFAULT '[7,3,1]', reminder_channels TEXT DEFAULT '["push"]', reminder_sent_days TEXT DEFAULT '[]', calendar_exported INTEGER NOT NULL DEFAULT 0, exported_at TEXT, created_at TEXT NOT NULL DEFAULT (datetime('now')))`,
    `CREATE TABLE IF NOT EXISTS chat_messages (id INTEGER PRIMARY KEY AUTOINCREMENT, document_id INTEGER NOT NULL, user_id INTEGER NOT NULL, session_id TEXT NOT NULL, role TEXT NOT NULL, message TEXT NOT NULL, cited_clause_ids TEXT, cited_pages TEXT, tokens_used INTEGER, response_time REAL, created_at TEXT NOT NULL DEFAULT (datetime('now')))`,
  ]) {
    try { db.run(sql.raw(stmt)); } catch { /* exists */ }
  }

  for (const col of [
    `ALTER TABLE deadlines ADD COLUMN exported_at TEXT`,
    `ALTER TABLE deadlines ADD COLUMN reminder_enabled INTEGER NOT NULL DEFAULT 1`,
    `ALTER TABLE deadlines ADD COLUMN reminder_times TEXT DEFAULT '[7,3,1]'`,
    `ALTER TABLE deadlines ADD COLUMN reminder_channels TEXT DEFAULT '["push"]'`,
    `ALTER TABLE deadlines ADD COLUMN reminder_sent_days TEXT DEFAULT '[]'`,
  ]) {
    try { db.run(sql.raw(col)); } catch { /* already */ }
  }

  db.insert(users).values({ fullName: 'F16', email: `f16-${Date.now()}@t.com`, passwordHash: 'x' }).run();
  const user = db.select().from(users).all().pop()!;

  db.insert(documents).values({
    userId: user.id,
    originalName: 'lease.txt',
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
    documentType: 'rental_agreement',
  }).run();
  const analysis = db.select().from(analysisResults).all().pop()!;

  db.insert(clauses).values({
    documentId: doc.id,
    analysisId: analysis.id,
    clauseNumber: 3,
    clauseTitle: 'Early Termination',
    originalText: 'Tenant may terminate early with 60 days written notice and payment of one month rent.',
    plainEnglishText: 'You can leave early if you give 60 days notice and pay one extra month.',
    pageNumber: 2,
  }).run();
  const clause = db.select().from(clauses).where(sql`${clauses.documentId} = ${doc.id}`).all()[0];

  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const due = tomorrow.toISOString().slice(0, 10);

  db.insert(deadlines).values({
    documentId: doc.id,
    userId: user.id,
    title: 'Termination Notice Window',
    description: 'Last day to give notice',
    dueDate: due,
    consequenceIfMissed: 'Auto-renewal',
    reminderEnabled: true,
    reminderTimes: JSON.stringify([1]),
    reminderChannels: JSON.stringify(['push']),
    reminderSentDays: JSON.stringify([]),
  }).run();
  const deadline = db.select().from(deadlines).where(sql`${deadlines.documentId} = ${doc.id}`).all().pop()!;

  // ICS smoke
  const ics = buildIcsCalendar([{
    id: deadline.id,
    title: deadline.title,
    dueDate: deadline.dueDate,
    consequenceIfMissed: deadline.consequenceIfMissed,
    documentName: doc.originalName,
  }]);
  if (!ics.includes('BEGIN:VEVENT') || !ics.includes(deadline.title.split(' ')[0])) {
    throw new Error('ICS build failed');
  }

  const now = new Date().toISOString();
  db.run(sql`UPDATE ${deadlines} SET calendar_exported = 1, exported_at = ${now} WHERE id = ${deadline.id}`);
  persistNow();
  const exported = db.select().from(deadlines).where(sql`${deadlines.id} = ${deadline.id}`).all()[0];
  if (!exported.calendarExported || !exported.exportedAt) throw new Error('export tracking failed');

  // Reminder match for due-tomorrow
  const days = daysUntilDue(due);
  if (days !== 1) throw new Error(`Expected daysUntil=1 got ${days}`);
  if (!shouldSendReminder(days, [1], [])) throw new Error('should send reminder');

  db.run(sql`UPDATE ${deadlines} SET reminder_times = ${JSON.stringify([1])}, reminder_sent_days = ${JSON.stringify([])} WHERE id = ${deadline.id}`);

  // Chat retrieval + citation path (no live AI)
  const retrieved = retrieveRelevantClauses('Can I terminate early?', [clause], 5, 0.15);
  if (retrieved.length < 1) throw new Error('retrieval missed termination clause');

  const fakeAi = `Yes. [Clause 3 — Early Termination] (Page 2)`;
  const resolved = resolveCitations(fakeAi, [clause]);
  if (resolved.citationConfidence !== 'high' || !resolved.citedClauseIds.includes(clause.id)) {
    throw new Error('citation resolve failed');
  }

  const sessionId = 'test-session-f16';
  db.insert(chatMessages).values({
    documentId: doc.id,
    userId: user.id,
    sessionId,
    role: 'user',
    message: 'Can I terminate early?',
  }).run();
  db.insert(chatMessages).values({
    documentId: doc.id,
    userId: user.id,
    sessionId,
    role: 'assistant',
    message: fakeAi,
    citedClauseIds: JSON.stringify(resolved.citedClauseIds),
    citedPages: JSON.stringify(resolved.citedPages),
  }).run();
  persistNow();

  const history = db.select().from(chatMessages).where(
    sql`${chatMessages.documentId} = ${doc.id} AND ${chatMessages.sessionId} = ${sessionId}`
  ).all();
  if (history.length !== 2) throw new Error('chat history not saved');
  const assistant = history.find((m) => m.role === 'assistant')!;
  const ids = JSON.parse(assistant.citedClauseIds || '[]');
  if (!ids.includes(clause.id)) throw new Error('cited_clause_ids not persisted');

  console.log('F16–F19 integration smoke OK', {
    deadlineId: deadline.id,
    exportedAt: exported.exportedAt,
    daysUntil: days,
    cited: resolved.citedClauseIds,
    messages: history.length,
  });

  closeDatabase();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
