-- LegiSense PostgreSQL Schema
-- Generated from Drizzle ORM models

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone_number TEXT,
  password_hash TEXT,
  auth_provider TEXT NOT NULL DEFAULT 'email',
  profile_photo_url TEXT,
  profession TEXT,
  preferred_language TEXT NOT NULL DEFAULT 'en',
  default_jurisdiction TEXT,
  nickname TEXT,
  preferred_document_types TEXT,
  oauth_subject TEXT,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT),
  updated_at TEXT NOT NULL DEFAULT (NOW()::TEXT),
  last_login_at TEXT
);

CREATE TABLE IF NOT EXISTS documents (
  id SERIAL PRIMARY KEY,
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
  country_code TEXT,
  state_code TEXT,
  detected_type TEXT,
  detected_type_confidence DOUBLE PRECISION,
  needs_type_confirmation BOOLEAN NOT NULL DEFAULT FALSE,
  upload_status TEXT NOT NULL DEFAULT 'uploading',
  processing_status TEXT NOT NULL DEFAULT 'pending',
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
  auto_delete_at TEXT,
  encryption_iv TEXT,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT),
  updated_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS analysis_results (
  id SERIAL PRIMARY KEY,
  document_id INTEGER NOT NULL UNIQUE REFERENCES documents(id),
  user_id INTEGER NOT NULL REFERENCES users(id),
  document_type TEXT,
  detected_type_confidence DOUBLE PRECISION,
  overall_risk_score DOUBLE PRECISION,
  risk_level TEXT,
  fairness_score DOUBLE PRECISION,
  favors_party TEXT,
  imbalance_reason TEXT,
  per_category_fairness TEXT,
  summary TEXT,
  key_parties TEXT,
  critical_dates TEXT,
  key_obligations TEXT,
  missing_clauses TEXT,
  jurisdiction_flags TEXT,
  jurisdiction_check_status TEXT DEFAULT 'pending',
  breach_scenarios TEXT,
  processing_time DOUBLE PRECISION,
  ai_model_used TEXT,
  analysis_language TEXT,
  translations TEXT DEFAULT '{}',
  counter_clauses_status TEXT DEFAULT 'skipped',
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS clauses (
  id SERIAL PRIMARY KEY,
  document_id INTEGER NOT NULL REFERENCES documents(id),
  analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
  clause_number INTEGER,
  clause_title TEXT,
  original_text TEXT NOT NULL,
  plain_english_text TEXT,
  reading_level TEXT,
  key_legal_terms TEXT,
  risk_level TEXT,
  risk_score DOUBLE PRECISION,
  risk_reason TEXT,
  risk_category TEXT,
  counter_suggestion TEXT,
  negotiation_tips TEXT,
  used_counter BOOLEAN NOT NULL DEFAULT FALSE,
  copied_at TEXT,
  is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
  page_number INTEGER,
  party_references TEXT,
  start_position INTEGER,
  end_position INTEGER,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS risk_items (
  id SERIAL PRIMARY KEY,
  analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
  clause_id INTEGER REFERENCES clauses(id),
  risk_type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  severity TEXT NOT NULL,
  severity_score DOUBLE PRECISION,
  recommendation TEXT,
  legal_reference TEXT,
  jurisdiction TEXT,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS deadlines (
  id SERIAL PRIMARY KEY,
  document_id INTEGER NOT NULL REFERENCES documents(id),
  user_id INTEGER NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  due_date TEXT NOT NULL,
  recurrence TEXT,
  urgency_level TEXT,
  deadline_type TEXT,
  party_responsible TEXT,
  consequence_if_missed TEXT,
  is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
  parent_id INTEGER,
  reminder_sent BOOLEAN NOT NULL DEFAULT FALSE,
  reminder_date TEXT,
  reminder_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  reminder_times TEXT DEFAULT '[7,3,1]',
  reminder_channels TEXT DEFAULT '["push"]',
  reminder_sent_days TEXT DEFAULT '[]',
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  is_dismissed BOOLEAN NOT NULL DEFAULT FALSE,
  calendar_exported BOOLEAN NOT NULL DEFAULT FALSE,
  exported_at TEXT,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS chat_messages (
  id SERIAL PRIMARY KEY,
  document_id INTEGER NOT NULL REFERENCES documents(id),
  user_id INTEGER NOT NULL REFERENCES users(id),
  session_id TEXT NOT NULL,
  role TEXT NOT NULL,
  message TEXT NOT NULL,
  cited_clause_ids TEXT,
  cited_pages TEXT,
  tokens_used INTEGER,
  response_time DOUBLE PRECISION,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  document_id INTEGER REFERENCES documents(id),
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  action_url TEXT,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  refresh_token TEXT NOT NULL UNIQUE,
  device_info TEXT,
  ip_address TEXT,
  expires_at TEXT NOT NULL,
  is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS usage_logs (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  action TEXT NOT NULL,
  document_id INTEGER REFERENCES documents(id),
  tokens_consumed INTEGER,
  processing_time DOUBLE PRECISION,
  provider TEXT,
  model TEXT,
  cost DOUBLE PRECISION,
  input_tokens INTEGER,
  output_tokens INTEGER,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS queue_jobs (
  id TEXT PRIMARY KEY,
  document_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  priority INTEGER NOT NULL DEFAULT 0,
  retry_count INTEGER NOT NULL DEFAULT 0,
  max_retries INTEGER NOT NULL DEFAULT 3,
  timeout_ms INTEGER NOT NULL DEFAULT 300000,
  error TEXT,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT),
  started_at TEXT,
  completed_at TEXT
);

CREATE TABLE IF NOT EXISTS glossary (
  id SERIAL PRIMARY KEY,
  term TEXT NOT NULL UNIQUE,
  definition TEXT NOT NULL,
  category TEXT,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS jurisdictions (
  id SERIAL PRIMARY KEY,
  country_code TEXT NOT NULL,
  country_name TEXT NOT NULL,
  state_code TEXT,
  state_name TEXT,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE INDEX IF NOT EXISTS idx_jurisdictions_country ON jurisdictions(country_code);

CREATE TABLE IF NOT EXISTS legal_rules (
  id SERIAL PRIMARY KEY,
  jurisdiction_id INTEGER NOT NULL REFERENCES jurisdictions(id),
  document_type TEXT NOT NULL,
  rule_title TEXT NOT NULL,
  rule_description TEXT NOT NULL,
  rule_type TEXT NOT NULL,
  clause_keywords TEXT NOT NULL DEFAULT '[]',
  legal_reference TEXT,
  severity TEXT NOT NULL DEFAULT 'warning',
  conflicting_jurisdictions TEXT NOT NULL DEFAULT '[]',
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS jurisdiction_flags (
  id SERIAL PRIMARY KEY,
  analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
  document_id INTEGER NOT NULL REFERENCES documents(id),
  clause_id INTEGER REFERENCES clauses(id),
  rule_id INTEGER NOT NULL REFERENCES legal_rules(id),
  flag_type TEXT NOT NULL,
  message TEXT NOT NULL,
  legal_reference TEXT,
  severity TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS jurisdiction_conflicts (
  id SERIAL PRIMARY KEY,
  analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
  document_id INTEGER NOT NULL REFERENCES documents(id),
  clause_id INTEGER REFERENCES clauses(id),
  clause_title TEXT,
  conflict_data TEXT NOT NULL DEFAULT '[]',
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS risk_patterns (
  id SERIAL PRIMARY KEY,
  pattern_name TEXT NOT NULL,
  pattern_category TEXT NOT NULL,
  severity TEXT NOT NULL,
  trigger_keywords TEXT NOT NULL DEFAULT '[]',
  explanation TEXT NOT NULL,
  recommendation TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS clause_risk_flags (
  id SERIAL PRIMARY KEY,
  clause_id INTEGER NOT NULL REFERENCES clauses(id),
  document_id INTEGER NOT NULL REFERENCES documents(id),
  analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
  pattern_id INTEGER NOT NULL REFERENCES risk_patterns(id),
  match_type TEXT NOT NULL,
  match_confidence DOUBLE PRECISION NOT NULL DEFAULT 80,
  flagged_text_snippet TEXT,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS community_risk_feedback (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  document_id INTEGER NOT NULL REFERENCES documents(id),
  clause_id INTEGER NOT NULL REFERENCES clauses(id),
  pattern_id INTEGER REFERENCES risk_patterns(id),
  feedback_type TEXT NOT NULL,
  note TEXT,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS required_clauses_templates (
  id SERIAL PRIMARY KEY,
  document_type TEXT NOT NULL,
  clause_name TEXT NOT NULL,
  importance TEXT NOT NULL,
  why_needed TEXT NOT NULL,
  example_text TEXT,
  detection_keywords TEXT NOT NULL DEFAULT '[]',
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS share_links (
  id SERIAL PRIMARY KEY,
  document_id INTEGER NOT NULL REFERENCES documents(id),
  user_id INTEGER NOT NULL REFERENCES users(id),
  token TEXT NOT NULL UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  views INTEGER NOT NULL DEFAULT 0,
  expires_at TEXT,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS clause_notes (
  id SERIAL PRIMARY KEY,
  clause_id INTEGER NOT NULL REFERENCES clauses(id),
  document_id INTEGER NOT NULL REFERENCES documents(id),
  user_id INTEGER NOT NULL REFERENCES users(id),
  note TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT),
  updated_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS playbook_rules (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  rule_text TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'general',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS playbook_flags (
  id SERIAL PRIMARY KEY,
  document_id INTEGER NOT NULL REFERENCES documents(id),
  analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
  clause_id INTEGER NOT NULL REFERENCES clauses(id),
  rule_id INTEGER NOT NULL REFERENCES playbook_rules(id),
  message TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS api_keys (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  name TEXT NOT NULL DEFAULT 'default',
  key_prefix TEXT NOT NULL,
  key_hash TEXT NOT NULL UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  daily_count INTEGER NOT NULL DEFAULT 0,
  daily_reset TEXT,
  last_used_at TEXT,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

CREATE TABLE IF NOT EXISTS document_collaborators (
  id SERIAL PRIMARY KEY,
  document_id INTEGER NOT NULL REFERENCES documents(id),
  invited_by INTEGER NOT NULL REFERENCES users(id),
  email TEXT NOT NULL,
  user_id INTEGER REFERENCES users(id),
  role TEXT NOT NULL DEFAULT 'viewer',
  token TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT)
);

-- Jobs table for queue system
CREATE TABLE IF NOT EXISTS jobs (
  id TEXT PRIMARY KEY,
  queue_name TEXT NOT NULL,
  name TEXT NOT NULL,
  data TEXT NOT NULL DEFAULT '{}',
  opts TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'pending',
  priority INTEGER NOT NULL DEFAULT 0,
  attempt INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 3,
  retry_count INTEGER NOT NULL DEFAULT 0,
  error TEXT,
  delay_until TEXT,
  repeat_job_key TEXT,
  created_at TEXT NOT NULL DEFAULT (NOW()::TEXT),
  started_at TEXT,
  completed_at TEXT,
  failed_at TEXT,
  returnvalue TEXT
);

CREATE INDEX IF NOT EXISTS idx_jobs_queue_status ON jobs(queue_name, status, priority);
CREATE INDEX IF NOT EXISTS idx_jobs_repeat_key ON jobs(repeat_job_key);
