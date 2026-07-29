import http from 'http';
import app from './app';
import { initDatabase, closeDatabase, persistNow } from './config/database';
import { sql } from 'drizzle-orm';
import {
  users, documents, analysisResults,
  clauses, riskItems, deadlines, chatMessages,
  notifications, sessions, usageLogs, queueJobs,
  glossary,
} from './models';
import { legalGlossary } from './data/legalGlossary';
import { initSocketIO, closeSocketIO } from './services/socketService';
import { startQueueSystem, stopQueueSystem } from './queue';

const server = http.createServer(app);
const port = Number(process.env.PORT) || 3001;

async function start() {
  const db = await initDatabase();

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${users} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone_number TEXT,
    password_hash TEXT,
    auth_provider TEXT NOT NULL DEFAULT 'email',
    profile_photo_url TEXT,
    profession TEXT,
    preferred_language TEXT NOT NULL DEFAULT 'en',
    default_jurisdiction TEXT,
    is_verified INTEGER NOT NULL DEFAULT 0,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_login_at TEXT
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${documents} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id),
    original_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    file_format TEXT NOT NULL,
    file_size INTEGER,
    page_count INTEGER,
    source_type TEXT NOT NULL,
    source_url TEXT,
    raw_text TEXT,
    detected_language TEXT,
    upload_status TEXT NOT NULL DEFAULT 'uploading',
    processing_status TEXT NOT NULL DEFAULT 'pending',
    is_deleted INTEGER NOT NULL DEFAULT 0,
    auto_delete_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${analysisResults} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id INTEGER NOT NULL UNIQUE REFERENCES documents(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    document_type TEXT,
    detected_type_confidence REAL,
    overall_risk_score REAL,
    risk_level TEXT,
    fairness_score REAL,
    favors_party TEXT,
    summary TEXT,
    key_parties TEXT,
    critical_dates TEXT,
    key_obligations TEXT,
    missing_clauses TEXT,
    jurisdiction_flags TEXT,
    breach_scenarios TEXT,
    processing_time REAL,
    ai_model_used TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${clauses} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id INTEGER NOT NULL REFERENCES documents(id),
    analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
    clause_number INTEGER,
    clause_title TEXT,
    original_text TEXT NOT NULL,
    plain_english_text TEXT,
    risk_level TEXT,
    risk_score REAL,
    risk_reason TEXT,
    risk_category TEXT,
    counter_suggestion TEXT,
    is_flagged INTEGER NOT NULL DEFAULT 0,
    page_number INTEGER,
    start_position INTEGER,
    end_position INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${riskItems} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
    clause_id INTEGER REFERENCES clauses(id),
    risk_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    severity TEXT NOT NULL,
    severity_score REAL,
    recommendation TEXT,
    legal_reference TEXT,
    jurisdiction TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${deadlines} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id INTEGER NOT NULL REFERENCES documents(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    title TEXT NOT NULL,
    description TEXT,
    due_date TEXT NOT NULL,
    recurrence TEXT,
    urgency_level TEXT,
    reminder_sent INTEGER NOT NULL DEFAULT 0,
    reminder_date TEXT,
    is_completed INTEGER NOT NULL DEFAULT 0,
    is_dismissed INTEGER NOT NULL DEFAULT 0,
    calendar_exported INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${chatMessages} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id INTEGER NOT NULL REFERENCES documents(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    session_id TEXT NOT NULL,
    role TEXT NOT NULL,
    message TEXT NOT NULL,
    cited_clause_ids TEXT,
    cited_pages TEXT,
    tokens_used INTEGER,
    response_time REAL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${notifications} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id),
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    document_id INTEGER REFERENCES documents(id),
    is_read INTEGER NOT NULL DEFAULT 0,
    action_url TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${sessions} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id),
    refresh_token TEXT NOT NULL UNIQUE,
    device_info TEXT,
    ip_address TEXT,
    expires_at TEXT NOT NULL,
    is_revoked INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${usageLogs} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id),
    action TEXT NOT NULL,
    document_id INTEGER REFERENCES documents(id),
    tokens_consumed INTEGER,
    processing_time REAL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${queueJobs} (
    id TEXT PRIMARY KEY,
    document_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    priority INTEGER NOT NULL DEFAULT 0,
    retry_count INTEGER NOT NULL DEFAULT 0,
    max_retries INTEGER NOT NULL DEFAULT 3,
    timeout_ms INTEGER NOT NULL DEFAULT 300000,
    error TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    started_at TEXT,
    completed_at TEXT
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${glossary} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    term TEXT NOT NULL UNIQUE,
    definition TEXT NOT NULL,
    category TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  try { db.run(sql`ALTER TABLE ${clauses} ADD COLUMN reading_level TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE ${clauses} ADD COLUMN key_legal_terms TEXT`); } catch {}

  try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN provider TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN model TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN cost REAL`); } catch {}
  try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN input_tokens INTEGER`); } catch {}
  try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN output_tokens INTEGER`); } catch {}
  try { db.run(sql`ALTER TABLE documents ADD COLUMN encryption_iv TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE analysis_results ADD COLUMN breach_scenarios TEXT`); } catch {}

  const existingTerms = db.select({ count: sql<number>`count(*)` }).from(glossary).all();
  if (existingTerms[0]?.count === 0) {
    for (const entry of legalGlossary) {
      db.insert(glossary).values({ term: entry.term, definition: entry.definition, category: entry.category }).run();
    }
    console.log(`Seeded ${legalGlossary.length} legal glossary terms.`);
  }

  console.log('All 12 tables created/verified.');
  persistNow();

  initSocketIO(server);

  await startQueueSystem();

  server.listen(port, () => {
    console.log(`Legisense API listening on http://localhost:${port}`);
  });
}

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});

process.on('SIGINT', async () => {
  await stopQueueSystem();
  await closeSocketIO();
  closeDatabase();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await stopQueueSystem();
  await closeSocketIO();
  closeDatabase();
  process.exit(0);
});
