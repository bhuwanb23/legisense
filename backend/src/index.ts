import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import { initDatabase, closeDatabase, persistNow } from './config/database';
import { sql } from 'drizzle-orm';
import {
  users, documents, analysisResults,
  clauses, riskItems, deadlines, chatMessages,
  notifications, sessions, usageLogs,
} from './models';
import {
  corsMiddleware,
  requestLogger,
  rateLimiter,
  errorHandler,
  notFoundHandler,
} from './middleware';
import documentRoutes from './routes/documentRoutes';
import authRoutes from './routes/authRoutes';
import userRoutes from './routes/userRoutes';
import { startAnalysisWorker } from './jobs/analysisWorker';

const app = express();
const port = Number(process.env.PORT) || 3001;

app.use(corsMiddleware);
app.use(requestLogger);
app.use(rateLimiter);
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'legisense-backend',
    timestamp: new Date().toISOString(),
  });
});

app.use('/api/documents', documentRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

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

  console.log('All 10 tables created/verified.');
  persistNow();

  startAnalysisWorker();

  app.listen(port, () => {
    console.log(`Legisense API listening on http://localhost:${port}`);
  });
}

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});

process.on('SIGINT', () => {
  closeDatabase();
  process.exit(0);
});

process.on('SIGTERM', () => {
  closeDatabase();
  process.exit(0);
});
