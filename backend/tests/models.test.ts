import initSqlJs, { type Database } from 'sql.js';
import { drizzle, type SQLJsDatabase } from 'drizzle-orm/sql-js';
import { sql } from 'drizzle-orm';
import {
  users, documents, analysisResults,
  clauses, riskItems, deadlines, chatMessages,
  notifications, sessions, usageLogs,
} from '../src/models';

let sqlClient: Database;
let db: SQLJsDatabase;
let seed: { user: any; doc: any; analysis: any };

const results: { test: string; pass: boolean; detail?: string }[] = [];

function assert(condition: boolean, test: string, detail?: string) {
  results.push({ test, pass: condition, detail });
  console.log(`  ${condition ? '✅' : '❌'} ${test}${detail ? ` — ${detail}` : ''}`);
}

async function setup() {
  const SQL = await initSqlJs();
  sqlClient = new SQL.Database();
  sqlClient.run('PRAGMA foreign_keys = ON');
  db = drizzle(sqlClient);

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
    nickname TEXT,
    preferred_document_types TEXT,
    oauth_subject TEXT,
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
    detected_type TEXT,
    detected_type_confidence REAL,
    needs_type_confirmation INTEGER NOT NULL DEFAULT 0,
    country_code TEXT,
    state_code TEXT,
    upload_status TEXT NOT NULL DEFAULT 'uploading',
    processing_status TEXT NOT NULL DEFAULT 'pending',
    is_deleted INTEGER NOT NULL DEFAULT 0,
    is_favorite INTEGER NOT NULL DEFAULT 0,
    auto_delete_at TEXT,
    encryption_iv TEXT,
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
    imbalance_reason TEXT,
    per_category_fairness TEXT,
    summary TEXT,
    key_parties TEXT,
    critical_dates TEXT,
    key_obligations TEXT,
    missing_clauses TEXT,
    jurisdiction_flags TEXT,
    breach_scenarios TEXT,
    jurisdiction_check_status TEXT DEFAULT 'pending',
    analysis_language TEXT,
    translations TEXT DEFAULT '{}',
    counter_clauses_status TEXT DEFAULT 'skipped',
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
    party_references TEXT,
    start_position INTEGER,
    end_position INTEGER,
    reading_level TEXT,
    key_legal_terms TEXT,
    negotiation_tips TEXT,
    used_counter INTEGER NOT NULL DEFAULT 0,
    copied_at TEXT,
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
    exported_at TEXT,
    reminder_enabled INTEGER NOT NULL DEFAULT 1,
    reminder_times TEXT DEFAULT '[7,3,1]',
    reminder_channels TEXT DEFAULT '["push"]',
    reminder_sent_days TEXT DEFAULT '[]',
    deadline_type TEXT,
    party_responsible TEXT,
    consequence_if_missed TEXT,
    is_recurring INTEGER NOT NULL DEFAULT 0,
    parent_id INTEGER,
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
    provider TEXT,
    model TEXT,
    cost REAL,
    input_tokens INTEGER,
    output_tokens INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )`);

  seed = await seedBase();
}

async function seedBase() {
  const user = await db.insert(users).values({
    fullName: 'Test User',
    email: 'test@legisense.com',
    authProvider: 'email',
  }).returning();

  const doc = await db.insert(documents).values({
    userId: user[0].id,
    originalName: 'TestContract.pdf',
    storagePath: '/uploads/test.pdf',
    fileFormat: 'pdf',
    sourceType: 'file_upload',
  }).returning();

  const analysis = await db.insert(analysisResults).values({
    documentId: doc[0].id,
    userId: user[0].id,
    documentType: 'Rental',
    riskLevel: 'medium',
  }).returning();

  return { user: user[0], doc: doc[0], analysis: analysis[0] };
}

async function testUserModel() {
  console.log('\n🧑 Testing User Model');

  const insertResult = await db.insert(users).values({
    fullName: 'Bhawarlal Bhuwan',
    email: 'bhuwan@legisense.com',
    phoneNumber: '+91-9876543210',
    passwordHash: '$2b$10$hashedpassword',
    authProvider: 'email',
    profession: 'lawyer',
    preferredLanguage: 'en',
    defaultJurisdiction: JSON.stringify({ country: 'India', state: 'Rajasthan' }),
    isVerified: true,
    isActive: true,
  }).returning();

  assert(insertResult.length === 1, 'Insert user returns 1 row');
  assert(insertResult[0].fullName === 'Bhawarlal Bhuwan', 'fullName stored correctly');
  assert(insertResult[0].email === 'bhuwan@legisense.com', 'email stored correctly');
  assert(insertResult[0].authProvider === 'email', 'authProvider defaults correctly');
  assert(insertResult[0].isVerified === true, 'isVerified boolean stored correctly');
  assert(insertResult[0].isActive === true, 'isActive boolean stored correctly');
  assert(insertResult[0].preferredLanguage === 'en', 'preferredLanguage defaults to en');

  const allUsers = await db.select().from(users);
  assert(allUsers.length >= 2, 'Select returns all users after inserts');

  const found = await db.select().from(users).where(sql`${users.email} = 'bhuwan@legisense.com'`);
  assert(found.length === 1, 'Query by email works');

  const notFound = await db.select().from(users).where(sql`${users.email} = 'nonexistent@test.com'`);
  assert(notFound.length === 0, 'Query for nonexistent email returns empty');

  try {
    await db.insert(users).values({
      fullName: 'Duplicate',
      email: 'bhuwan@legisense.com',
    });
    assert(false, 'Duplicate email should throw', 'No error thrown');
  } catch {
    assert(true, 'Duplicate email throws error (UNIQUE constraint)');
  }

  const oauthUser = await db.insert(users).values({
    fullName: 'Google User',
    email: 'google@test.com',
    authProvider: 'google',
  }).returning();
  assert(oauthUser[0].passwordHash === null, 'OAuth user has null passwordHash');
  assert(oauthUser[0].authProvider === 'google', 'OAuth provider stored correctly');
}

async function testDocumentModel() {
  console.log('\n📄 Testing Document Model');

  const user = (await db.select().from(users).limit(1))[0];

  const doc = await db.insert(documents).values({
    userId: user.id,
    originalName: 'RentAgreement_2024.pdf',
    storagePath: '/uploads/rent-agreement.pdf',
    fileFormat: 'pdf',
    fileSize: 1024000,
    pageCount: 12,
    sourceType: 'file_upload',
    rawText: 'This is a rental agreement between Party A and Party B...',
    detectedLanguage: 'en',
    uploadStatus: 'uploaded',
    processingStatus: 'completed',
  }).returning();

  assert(doc.length === 1, 'Insert document returns 1 row');
  assert(doc[0].userId === user.id, 'userId links to user correctly');
  assert(doc[0].originalName === 'RentAgreement_2024.pdf', 'originalName stored');
  assert(doc[0].fileFormat === 'pdf', 'fileFormat stored');
  assert(doc[0].fileSize === 1024000, 'fileSize stored as integer');
  assert(doc[0].uploadStatus === 'uploaded', 'uploadStatus stored');
  assert(doc[0].processingStatus === 'completed', 'processingStatus stored');
  assert(doc[0].isDeleted === false, 'isDeleted defaults to false');

  const userDocs = await db.select().from(documents).where(sql`${documents.userId} = ${user.id}`);
  assert(userDocs.length >= 1, 'Query by userId works');
}

async function testAnalysisResultModel() {
  console.log('\n🤖 Testing AnalysisResult Model');

  const { user, doc } = seed;

  const allResults = await db.select().from(analysisResults);
  const result = allResults.find((r) => r.documentId === doc.id);
  assert(result !== undefined, 'Analysis result created during seed');
  assert(result!.documentType === 'Rental', 'documentType stored');
  assert(result!.riskLevel === 'medium', 'riskLevel stored');

  try {
    await db.insert(analysisResults).values({
      documentId: doc.id,
      userId: user.id,
    });
    assert(false, 'Duplicate documentId should throw (1:1)', 'No error thrown');
  } catch {
    assert(true, 'Duplicate documentId throws error (UNIQUE constraint — 1:1)');
  }
}

async function testClauseModel() {
  console.log('\n📑 Testing Clause Model');

  const { user, doc, analysis } = seed;

  const clause = await db.insert(clauses).values({
    documentId: doc.id,
    analysisId: analysis.id,
    clauseNumber: 5,
    clauseTitle: 'Termination Clause',
    originalText: 'Either party may terminate this agreement with 30 days written notice.',
    plainEnglishText: 'You can end this contract by giving 30 days notice in writing.',
    riskLevel: 'medium',
    riskScore: 45,
    riskReason: '30-day notice period may be insufficient for complex arrangements.',
    riskCategory: 'termination',
    counterSuggestion: 'Consider extending notice period to 60 days for commercial leases.',
    isFlagged: false,
    pageNumber: 3,
    startPosition: 1500,
    endPosition: 1800,
  }).returning();

  assert(clause.length === 1, 'Insert clause returns 1 row');
  assert(clause[0].documentId === doc.id, 'documentId links correctly');
  assert(clause[0].analysisId === analysis.id, 'analysisId links correctly');
  assert(clause[0].clauseNumber === 5, 'clauseNumber stored');
  assert(clause[0].clauseTitle === 'Termination Clause', 'clauseTitle stored');
  assert(clause[0].originalText.includes('terminate'), 'originalText stored');
  assert(clause[0].plainEnglishText!.includes('giving'), 'plainEnglishText stored');
  assert(clause[0].riskLevel === 'medium', 'riskLevel stored');
  assert(clause[0].riskScore === 45, 'riskScore stored');
  assert(clause[0].riskCategory === 'termination', 'riskCategory stored');
  assert(clause[0].isFlagged === false, 'isFlagged defaults to false');
  assert(clause[0].pageNumber === 3, 'pageNumber stored');
  assert(clause[0].startPosition === 1500, 'startPosition stored');
  assert(clause[0].endPosition === 1800, 'endPosition stored');

  const flagged = await db.insert(clauses).values({
    documentId: doc.id,
    analysisId: analysis.id,
    clauseNumber: 7,
    originalText: 'Party A shall not be liable for any damages.',
    riskLevel: 'high',
    riskScore: 85,
    riskCategory: 'legal',
    isFlagged: true,
  }).returning();
  assert(flagged[0].isFlagged === true, 'isFlagged can be set to true');

  const docClauses = await db.select().from(clauses).where(sql`${clauses.documentId} = ${doc.id}`);
  assert(docClauses.length === 2, 'Query by documentId returns all clauses');

  const highRisk = await db.select().from(clauses).where(sql`${clauses.riskLevel} = 'high'`);
  assert(highRisk.length >= 1, 'Query by riskLevel works');
}

async function testRiskItemModel() {
  console.log('\n⚠️  Testing Risk Item Model');

  const { doc, analysis } = seed;

  const clause = (await db.insert(clauses).values({
    documentId: doc.id,
    analysisId: analysis.id,
    clauseNumber: 10,
    originalText: 'Unlimited liability clause.',
    riskLevel: 'high',
  }).returning())[0];

  const risk = await db.insert(riskItems).values({
    analysisId: analysis.id,
    clauseId: clause.id,
    riskType: 'liability',
    title: 'Unlimited Liability Exposure',
    description: 'The contract imposes unlimited personal liability on Party B.',
    severity: 'critical',
    severityScore: 92,
    recommendation: 'Negotiate a liability cap of 12 months of contract value.',
    legalReference: 'Indian Contract Act, Section 73',
    jurisdiction: 'India',
  }).returning();

  assert(risk.length === 1, 'Insert risk item returns 1 row');
  assert(risk[0].analysisId === analysis.id, 'analysisId links correctly');
  assert(risk[0].clauseId === clause.id, 'clauseId links correctly');
  assert(risk[0].riskType === 'liability', 'riskType stored');
  assert(risk[0].title === 'Unlimited Liability Exposure', 'title stored');
  assert(risk[0].severity === 'critical', 'severity stored');
  assert(risk[0].severityScore === 92, 'severityScore stored');
  assert(risk[0].legalReference === 'Indian Contract Act, Section 73', 'legalReference stored');

  const noClauseRisk = await db.insert(riskItems).values({
    analysisId: analysis.id,
    riskType: 'missing',
    title: 'Missing Indemnity Clause',
    severity: 'high',
    severityScore: 70,
  }).returning();
  assert(noClauseRisk[0].clauseId === null, 'clauseId is nullable for missing risks');

  const analysisRisks = await db.select().from(riskItems).where(sql`${riskItems.analysisId} = ${analysis.id}`);
  assert(analysisRisks.length === 2, 'Query by analysisId returns all risks');
}

async function testDeadlineModel() {
  console.log('\n📅 Testing Deadline Model');

  const { user, doc } = seed;

  const deadline = await db.insert(deadlines).values({
    documentId: doc.id,
    userId: user.id,
    title: 'Rent Payment Due',
    description: 'Monthly rent of ₹15,000 due',
    dueDate: '2024-02-05',
    recurrence: 'monthly',
    urgencyLevel: 'upcoming',
    reminderSent: false,
    isCompleted: false,
    isDismissed: false,
    calendarExported: false,
  }).returning();

  assert(deadline.length === 1, 'Insert deadline returns 1 row');
  assert(deadline[0].documentId === doc.id, 'documentId links correctly');
  assert(deadline[0].userId === user.id, 'userId links correctly');
  assert(deadline[0].title === 'Rent Payment Due', 'title stored');
  assert(deadline[0].dueDate === '2024-02-05', 'dueDate stored');
  assert(deadline[0].recurrence === 'monthly', 'recurrence stored');
  assert(deadline[0].urgencyLevel === 'upcoming', 'urgencyLevel stored');
  assert(deadline[0].reminderSent === false, 'reminderSent defaults to false');
  assert(deadline[0].isCompleted === false, 'isCompleted defaults to false');
  assert(deadline[0].isDismissed === false, 'isDismissed defaults to false');
  assert(deadline[0].calendarExported === false, 'calendarExported defaults to false');

  const oneTime = await db.insert(deadlines).values({
    documentId: doc.id,
    userId: user.id,
    title: 'Contract Review Deadline',
    dueDate: '2024-03-01',
    recurrence: 'one-time',
    urgencyLevel: 'this_week',
  }).returning();
  assert(oneTime[0].recurrence === 'one-time', 'one-time recurrence stored');

  const userDeadlines = await db.select().from(deadlines).where(sql`${deadlines.userId} = ${user.id}`);
  assert(userDeadlines.length === 2, 'Query by userId returns all deadlines');
}

async function testChatMessageModel() {
  console.log('\n💬 Testing Chat Message Model');

  const { user, doc } = seed;

  const sessionId = 'sess_abc123';

  const userMsg = await db.insert(chatMessages).values({
    documentId: doc.id,
    userId: user.id,
    sessionId,
    role: 'user',
    message: 'What does the termination clause say?',
    tokensUsed: 0,
  }).returning();

  assert(userMsg.length === 1, 'Insert user message returns 1 row');
  assert(userMsg[0].documentId === doc.id, 'documentId links correctly');
  assert(userMsg[0].userId === user.id, 'userId links correctly');
  assert(userMsg[0].sessionId === sessionId, 'sessionId stored');
  assert(userMsg[0].role === 'user', 'role stored');
  assert(userMsg[0].message === 'What does the termination clause say?', 'message stored');

  const citedClauseIds = JSON.stringify([5, 7, 12]);
  const citedPages = JSON.stringify([3, 4]);

  const assistantMsg = await db.insert(chatMessages).values({
    documentId: doc.id,
    userId: user.id,
    sessionId,
    role: 'assistant',
    message: 'The termination clause allows either party to terminate with 30 days notice.',
    citedClauseIds,
    citedPages,
    tokensUsed: 150,
    responseTime: 2.3,
  }).returning();

  assert(assistantMsg[0].role === 'assistant', 'assistant role stored');
  assert(assistantMsg[0].tokensUsed === 150, 'tokensUsed stored');
  assert(assistantMsg[0].responseTime === 2.3, 'responseTime stored');

  const parsedClauses = JSON.parse(assistantMsg[0].citedClauseIds!);
  assert(parsedClauses.length === 3, 'citedClauseIds JSON roundtrip — array length');
  assert(parsedClauses[0] === 5, 'citedClauseIds JSON roundtrip — first element');

  const parsedPages = JSON.parse(assistantMsg[0].citedPages!);
  assert(parsedPages.length === 2, 'citedPages JSON roundtrip — array length');
  assert(parsedPages[1] === 4, 'citedPages JSON roundtrip — second element');

  const sessionMsgs = await db.select().from(chatMessages).where(sql`${chatMessages.sessionId} = ${sessionId}`);
  assert(sessionMsgs.length === 2, 'Query by sessionId returns conversation');
  assert(sessionMsgs[0].role === 'user', 'First message is user');
  assert(sessionMsgs[1].role === 'assistant', 'Second message is assistant');

  const docMsgs = await db.select().from(chatMessages).where(sql`${chatMessages.documentId} = ${doc.id}`);
  assert(docMsgs.length === 2, 'Query by documentId returns all messages');
}

async function testNotificationModel() {
  console.log('\n🔔 Testing Notification Model');

  const { user, doc } = seed;

  const notif = await db.insert(notifications).values({
    userId: user.id,
    type: 'analysis_complete',
    title: 'Analysis Complete',
    body: 'Your document "TestContract.pdf" has been analyzed.',
    documentId: doc.id,
    isRead: false,
    actionUrl: '/documents/1/analysis',
  }).returning();

  assert(notif.length === 1, 'Insert notification returns 1 row');
  assert(notif[0].userId === user.id, 'userId links correctly');
  assert(notif[0].type === 'analysis_complete', 'type stored');
  assert(notif[0].title === 'Analysis Complete', 'title stored');
  assert(notif[0].body!.includes('analyzed'), 'body stored');
  assert(notif[0].documentId === doc.id, 'documentId links correctly');
  assert(notif[0].isRead === false, 'isRead defaults to false');
  assert(notif[0].actionUrl === '/documents/1/analysis', 'actionUrl stored');

  const systemNotif = await db.insert(notifications).values({
    userId: user.id,
    type: 'system',
    title: 'Welcome to Legisense',
    body: 'Start by uploading your first document.',
  }).returning();
  assert(systemNotif[0].documentId === null, 'documentId is nullable for system notifications');

  const deadlineNotif = await db.insert(notifications).values({
    userId: user.id,
    type: 'deadline',
    title: 'Rent Payment Due Tomorrow',
    documentId: doc.id,
  }).returning();
  assert(deadlineNotif[0].type === 'deadline', 'deadline notification type stored');

  const userNotifs = await db.select().from(notifications).where(sql`${notifications.userId} = ${user.id}`);
  assert(userNotifs.length === 3, 'Query by userId returns all notifications');

  const unread = await db.select().from(notifications).where(sql`${notifications.isRead} = 0`);
  assert(unread.length >= 3, 'Query for unread notifications works');
}

async function testSessionModel() {
  console.log('\n🔑 Testing Session Model');

  const { user } = seed;

  const session = await db.insert(sessions).values({
    userId: user.id,
    refreshToken: 'rt_abc123xyz789',
    deviceInfo: 'Chrome 120 / Windows 11',
    ipAddress: '192.168.1.100',
    expiresAt: '2024-12-31T23:59:59.000Z',
    isRevoked: false,
  }).returning();

  assert(session.length === 1, 'Insert session returns 1 row');
  assert(session[0].userId === user.id, 'userId links correctly');
  assert(session[0].refreshToken === 'rt_abc123xyz789', 'refreshToken stored');
  assert(session[0].deviceInfo === 'Chrome 120 / Windows 11', 'deviceInfo stored');
  assert(session[0].ipAddress === '192.168.1.100', 'ipAddress stored');
  assert(session[0].expiresAt === '2024-12-31T23:59:59.000Z', 'expiresAt stored');
  assert(session[0].isRevoked === false, 'isRevoked defaults to false');

  try {
    await db.insert(sessions).values({
      userId: user.id,
      refreshToken: 'rt_abc123xyz789',
      expiresAt: '2025-01-01T00:00:00.000Z',
    });
    assert(false, 'Duplicate refreshToken should throw', 'No error thrown');
  } catch {
    assert(true, 'Duplicate refreshToken throws error (UNIQUE constraint)');
  }

  const userSessions = await db.select().from(sessions).where(sql`${sessions.userId} = ${user.id}`);
  assert(userSessions.length === 1, 'Query by userId returns sessions');

  const found = await db.select().from(sessions).where(sql`${sessions.refreshToken} = 'rt_abc123xyz789'`);
  assert(found.length === 1, 'Query by refreshToken works');
}

async function testUsageLogModel() {
  console.log('\n📊 Testing Usage Log Model');

  const { user, doc } = seed;

  const log1 = await db.insert(usageLogs).values({
    userId: user.id,
    action: 'document_uploaded',
    documentId: doc.id,
    processingTime: 1.2,
  }).returning();

  assert(log1.length === 1, 'Insert usage log returns 1 row');
  assert(log1[0].userId === user.id, 'userId links correctly');
  assert(log1[0].action === 'document_uploaded', 'action stored');
  assert(log1[0].documentId === doc.id, 'documentId links correctly');
  assert(log1[0].processingTime === 1.2, 'processingTime stored');

  const log2 = await db.insert(usageLogs).values({
    userId: user.id,
    action: 'analysis_run',
    documentId: doc.id,
    tokensConsumed: 2500,
    processingTime: 3.5,
  }).returning();
  assert(log2[0].tokensConsumed === 2500, 'tokensConsumed stored');

  const log3 = await db.insert(usageLogs).values({
    userId: user.id,
    action: 'chat_sent',
    tokensConsumed: 150,
    processingTime: 1.8,
  }).returning();
  assert(log3[0].documentId === null, 'documentId is nullable for chat actions');

  const userLogs = await db.select().from(usageLogs).where(sql`${usageLogs.userId} = ${user.id}`);
  assert(userLogs.length === 3, 'Query by userId returns all logs');

  const uploadLogs = await db.select().from(usageLogs).where(sql`${usageLogs.action} = 'document_uploaded'`);
  assert(uploadLogs.length >= 1, 'Query by action works');
}

function printSummary() {
  console.log('\n' + '='.repeat(60));
  const passed = results.filter((r) => r.pass).length;
  const failed = results.filter((r) => !r.pass).length;
  console.log(`Results: ${passed} passed, ${failed} failed, ${results.length} total`);
  console.log('='.repeat(60));

  if (failed > 0) {
    console.log('\nFailed tests:');
    results.filter((r) => !r.pass).forEach((r) => {
      console.log(`  ❌ ${r.test}${r.detail ? ` — ${r.detail}` : ''}`);
    });
  }

  return failed === 0;
}

async function main() {
  console.log('🧪 Legisense Database Model Tests\n');
  console.log('Setting up in-memory SQLite database...');

  await setup();
  console.log('Database ready.\n');

  await testUserModel();
  await testDocumentModel();
  await testAnalysisResultModel();
  await testClauseModel();
  await testRiskItemModel();
  await testDeadlineModel();
  await testChatMessageModel();
  await testNotificationModel();
  await testSessionModel();
  await testUsageLogModel();

  const allPassed = printSummary();

  sqlClient.close();
  process.exit(allPassed ? 0 : 1);
}

main().catch((err) => {
  console.error('Test runner failed:', err);
  process.exit(1);
});
