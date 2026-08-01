import http from 'http';
import app from './app';
import { initDatabase, closeDatabase, persistNow } from './config/database';
import { sql } from 'drizzle-orm';
import {
  users, documents, analysisResults,
  clauses, riskItems, deadlines, chatMessages,
  notifications, sessions, usageLogs, queueJobs,
  glossary, jurisdictions, legalRules, jurisdictionFlags, jurisdictionConflicts,
  riskPatterns, clauseRiskFlags, communityRiskFeedback, requiredClausesTemplates,
} from './models';
import { legalGlossary } from './data/legalGlossary';
import { seedJurisdictionsAndRules } from './data/seedJurisdictions';
import { seedRiskAndRequiredLibraries } from './data/seedRiskLibraries';
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
    reminder_enabled INTEGER NOT NULL DEFAULT 1,
    reminder_times TEXT DEFAULT '[7,3,1]',
    reminder_channels TEXT DEFAULT '["push"]',
    reminder_sent_days TEXT DEFAULT '[]',
    is_completed INTEGER NOT NULL DEFAULT 0,
    is_dismissed INTEGER NOT NULL DEFAULT 0,
    calendar_exported INTEGER NOT NULL DEFAULT 0,
    exported_at TEXT,
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

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${jurisdictions} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_code TEXT NOT NULL,
    country_name TEXT NOT NULL,
    state_code TEXT,
    state_name TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE INDEX IF NOT EXISTS idx_jurisdictions_country
    ON jurisdictions(country_code)`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${legalRules} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    jurisdiction_id INTEGER NOT NULL REFERENCES jurisdictions(id),
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

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${jurisdictionFlags} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
    document_id INTEGER NOT NULL REFERENCES documents(id),
    clause_id INTEGER REFERENCES clauses(id),
    rule_id INTEGER NOT NULL REFERENCES legal_rules(id),
    flag_type TEXT NOT NULL,
    message TEXT NOT NULL,
    legal_reference TEXT,
    severity TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${jurisdictionConflicts} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
    document_id INTEGER NOT NULL REFERENCES documents(id),
    clause_id INTEGER REFERENCES clauses(id),
    clause_title TEXT,
    conflict_data TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${riskPatterns} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern_name TEXT NOT NULL,
    pattern_category TEXT NOT NULL,
    severity TEXT NOT NULL,
    trigger_keywords TEXT NOT NULL DEFAULT '[]',
    explanation TEXT NOT NULL,
    recommendation TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${clauseRiskFlags} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    clause_id INTEGER NOT NULL REFERENCES clauses(id),
    document_id INTEGER NOT NULL REFERENCES documents(id),
    analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
    pattern_id INTEGER NOT NULL REFERENCES risk_patterns(id),
    match_type TEXT NOT NULL,
    match_confidence REAL NOT NULL DEFAULT 80,
    flagged_text_snippet TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${communityRiskFeedback} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id),
    document_id INTEGER NOT NULL REFERENCES documents(id),
    clause_id INTEGER NOT NULL REFERENCES clauses(id),
    pattern_id INTEGER REFERENCES risk_patterns(id),
    feedback_type TEXT NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  await db.run(sql`CREATE TABLE IF NOT EXISTS ${requiredClausesTemplates} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_type TEXT NOT NULL,
    clause_name TEXT NOT NULL,
    importance TEXT NOT NULL,
    why_needed TEXT NOT NULL,
    example_text TEXT,
    detection_keywords TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  try { db.run(sql`ALTER TABLE ${clauses} ADD COLUMN reading_level TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE ${clauses} ADD COLUMN key_legal_terms TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE ${clauses} ADD COLUMN negotiation_tips TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE ${clauses} ADD COLUMN used_counter INTEGER NOT NULL DEFAULT 0`); } catch {}
  try { db.run(sql`ALTER TABLE ${clauses} ADD COLUMN copied_at TEXT`); } catch {}

  try { db.run(sql`ALTER TABLE ${users} ADD COLUMN nickname TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE ${users} ADD COLUMN preferred_document_types TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE ${users} ADD COLUMN oauth_subject TEXT`); } catch {}

  try { db.run(sql`ALTER TABLE ${documents} ADD COLUMN detected_type TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE ${documents} ADD COLUMN detected_type_confidence REAL`); } catch {}
  try { db.run(sql`ALTER TABLE ${documents} ADD COLUMN needs_type_confirmation INTEGER NOT NULL DEFAULT 0`); } catch {}
  try { db.run(sql`ALTER TABLE ${documents} ADD COLUMN country_code TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE ${documents} ADD COLUMN state_code TEXT`); } catch {}

  try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN provider TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN model TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN cost REAL`); } catch {}
  try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN input_tokens INTEGER`); } catch {}
  try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN output_tokens INTEGER`); } catch {}
  try { db.run(sql`ALTER TABLE documents ADD COLUMN encryption_iv TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE analysis_results ADD COLUMN breach_scenarios TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE analysis_results ADD COLUMN jurisdiction_check_status TEXT DEFAULT 'pending'`); } catch {}
  try { db.run(sql`ALTER TABLE analysis_results ADD COLUMN analysis_language TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE analysis_results ADD COLUMN translations TEXT DEFAULT '{}'`); } catch {}
  try { db.run(sql`ALTER TABLE analysis_results ADD COLUMN counter_clauses_status TEXT DEFAULT 'skipped'`); } catch {}

  try { db.run(sql`ALTER TABLE deadlines ADD COLUMN deadline_type TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE deadlines ADD COLUMN party_responsible TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE deadlines ADD COLUMN consequence_if_missed TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE deadlines ADD COLUMN is_recurring INTEGER NOT NULL DEFAULT 0`); } catch {}
  try { db.run(sql`ALTER TABLE deadlines ADD COLUMN parent_id INTEGER`); } catch {}
  try { db.run(sql`ALTER TABLE deadlines ADD COLUMN exported_at TEXT`); } catch {}
  try { db.run(sql`ALTER TABLE deadlines ADD COLUMN reminder_enabled INTEGER NOT NULL DEFAULT 1`); } catch {}
  try { db.run(sql`ALTER TABLE deadlines ADD COLUMN reminder_times TEXT DEFAULT '[7,3,1]'`); } catch {}
  try { db.run(sql`ALTER TABLE deadlines ADD COLUMN reminder_channels TEXT DEFAULT '["push"]'`); } catch {}
  try { db.run(sql`ALTER TABLE deadlines ADD COLUMN reminder_sent_days TEXT DEFAULT '[]'`); } catch {}

  const existingTerms = db.select({ count: sql<number>`count(*)` }).from(glossary).all();
  if (Number(existingTerms[0]?.count ?? 0) === 0) {
    let seeded = 0;
    for (const entry of legalGlossary) {
      try {
        db.insert(glossary).values({ term: entry.term, definition: entry.definition, category: entry.category }).run();
        seeded++;
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        if (!message.includes('UNIQUE constraint failed')) throw err;
      }
    }
    console.log(`Seeded ${seeded} legal glossary terms.`);
  }

  seedJurisdictionsAndRules();
  seedRiskAndRequiredLibraries();

  console.log('All tables created/verified.');
  persistNow();

  initSocketIO(server);

  await startQueueSystem();

  // Long local-LLM process calls (extract + Ollama) need generous timeouts.
  server.timeout = 600_000;
  server.headersTimeout = 610_000;
  server.requestTimeout = 600_000;
  server.keepAliveTimeout = 120_000;

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
