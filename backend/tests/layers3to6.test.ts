import { Request, Response, NextFunction } from 'express';

import { initDatabase, getDb, closeDatabase, persistNow } from '../src/config/database';
import { sql } from 'drizzle-orm';
import {
  users, documents, analysisResults, clauses, riskItems,
  deadlines, chatMessages, notifications,
} from '../src/models';

const results: { test: string; pass: boolean; detail?: string }[] = [];

function assert(condition: boolean, test: string, detail?: string) {
  results.push({ test, pass: condition, detail });
  console.log(`  ${condition ? '✅' : '❌'} ${test}${detail ? ` — ${detail}` : ''}`);
}

function mockReq(overrides?: Partial<Request>): Request {
  return {
    headers: {},
    body: {},
    query: {},
    params: {},
    method: 'GET',
    originalUrl: '/test',
    ip: '127.0.0.1',
    socket: { remoteAddress: '127.0.0.1' },
    ...overrides,
  } as unknown as Request;
}

function mockRes(): Response {
  const res = {
    statusCode: 200,
    body: null as unknown,
    finished: false,
  } as unknown as Response;

  Object.defineProperty(res, 'status', {
    value: (code: number) => {
      res.statusCode = code;
      return res;
    },
    writable: true,
    configurable: true,
  });

  Object.defineProperty(res, 'json', {
    value: (data: unknown) => {
      res.body = data;
      res.finished = true;
      return res;
    },
    writable: true,
    configurable: true,
  });

  return res;
}

function mockNext(): NextFunction {
  return ((err?: unknown) => {
    if (err) throw err;
  }) as unknown as NextFunction;
}

function authedReq(userId: number, email: string, overrides: Partial<Request> = {}): Request {
  return mockReq({
    user: { id: userId, email, fullName: 'Test User', authProvider: 'email', isActive: true },
    ...overrides,
  });
}

async function run() {
  console.log('🧪 Layers 3-6 Tests (Analysis, Chat, Deadlines, Notifications)\n');

  await initDatabase();
  const db = getDb();

  // Clean slate — delete in reverse FK order
  db.run(sql`DELETE FROM ${chatMessages}`);
  db.run(sql`DELETE FROM ${deadlines}`);
  db.run(sql`DELETE FROM ${notifications}`);
  db.run(sql`DELETE FROM ${riskItems}`);
  db.run(sql`DELETE FROM ${clauses}`);
  db.run(sql`DELETE FROM ${analysisResults}`);
  db.run(sql`DELETE FROM ${documents}`);
  db.run(sql`DELETE FROM ${users}`);
  persistNow();

  // ═══════════════════════════════════════════════════
  //  SETUP: Create test users + documents via ORM
  // ═══════════════════════════════════════════════════
  console.log('── Setup ──');

  // User 1
  db.insert(users).values({
    fullName: 'Test User',
    email: 'layers@test.com',
    passwordHash: 'hash',
    authProvider: 'email',
    isActive: true,
  }).run();

  const userRow = db.select().from(users).where(sql`${users.email} = 'layers@test.com'`).all();
  const userId = userRow[0].id;
  console.log(`  ℹ️  User 1 ID: ${userId}`);

  // User 2 (for cross-user tests)
  db.insert(users).values({
    fullName: 'Other User',
    email: 'other@test.com',
    passwordHash: 'hash',
    authProvider: 'email',
    isActive: true,
  }).run();

  const otherUserRow = db.select().from(users).where(sql`${users.email} = 'other@test.com'`).all();
  const otherUserId = otherUserRow[0].id;
  console.log(`  ℹ️  User 2 ID: ${otherUserId}`);

  // Document for user 1 — completed
  db.insert(documents).values({
    userId,
    originalName: 'contract.pdf',
    storagePath: '/uploads/test.pdf',
    fileFormat: 'pdf',
    sourceType: 'file_upload',
    rawText: 'Full contract text here',
    processingStatus: 'completed',
    uploadStatus: 'uploaded',
  }).run();

  const docRow = db.select().from(documents).where(sql`${documents.userId} = ${userId}`).all();
  const docId = docRow[0].id;
  console.log(`  ℹ️  Document 1 ID: ${docId}`);

  // Document for user 2
  db.insert(documents).values({
    userId: otherUserId,
    originalName: 'other-contract.pdf',
    storagePath: '/uploads/other.pdf',
    fileFormat: 'pdf',
    sourceType: 'file_upload',
    rawText: 'Other contract text',
    processingStatus: 'completed',
    uploadStatus: 'uploaded',
  }).run();

  // Document for user 1 — pending analysis
  db.insert(documents).values({
    userId,
    originalName: 'pending.pdf',
    storagePath: '/uploads/pending.pdf',
    fileFormat: 'pdf',
    sourceType: 'file_upload',
    rawText: 'Pending text',
    processingStatus: 'pending',
    uploadStatus: 'uploaded',
  }).run();

  const pendingDocRow = db.select().from(documents).where(sql`${documents.originalName} = 'pending.pdf'`).all();
  const pendingDocId = pendingDocRow[0].id;
  persistNow();

  // ═══════════════════════════════════════════════════
  //  1. ANALYSIS CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 1. Analysis Controller ──');

  const {
    startAnalysis,
    getAnalysis,
    getClauses,
    getRisks,
    getSummary,
  } = await import('../src/controllers/analysisController');

  // 1a. startAnalysis — success
  const startRes = mockRes();
  await startAnalysis(
    authedReq(userId, 'layers@test.com', { params: { documentId: String(docId) } }),
    startRes,
    mockNext()
  );
  assert(startRes.statusCode === 202, 'startAnalysis returns 202');
  const startBody = startRes.body as Record<string, unknown>;
  assert(startBody.success === true, 'startAnalysis returns success');
  const startData = startBody.data as Record<string, unknown>;
  assert(startData.status === 'pending', 'startAnalysis returns pending status');
  assert(typeof startData.jobId === 'string', 'startAnalysis returns jobId');

  // 1b. startAnalysis — already processing (409, returned as response not thrown)
  db.run(sql`UPDATE ${documents} SET processing_status = 'processing' WHERE id = ${docId}`);
  persistNow();

  const alreadyRes = mockRes();
  await startAnalysis(
    authedReq(userId, 'layers@test.com', { params: { documentId: String(docId) } }),
    alreadyRes,
    mockNext()
  );
  assert(alreadyRes.statusCode === 409, 'startAnalysis returns 409 when already processing');

  // Reset status
  db.run(sql`UPDATE ${documents} SET processing_status = 'completed' WHERE id = ${docId}`);
  persistNow();

  // 1c. startAnalysis — document not found (404)
  let notFoundThrew = false;
  try {
    const nfRes = mockRes();
    await startAnalysis(
      authedReq(userId, 'layers@test.com', { params: { documentId: '99999' } }),
      nfRes,
      mockNext()
    );
  } catch (e: unknown) {
    notFoundThrew = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(notFoundThrew, 'startAnalysis throws 404 for nonexistent document');

  // 1d. startAnalysis — cross-user isolation (404)
  let crossUserThrew = false;
  try {
    const crossRes = mockRes();
    await startAnalysis(
      authedReq(otherUserId, 'other@test.com', { params: { documentId: String(docId) } }),
      crossRes,
      mockNext()
    );
  } catch (e: unknown) {
    crossUserThrew = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(crossUserThrew, 'startAnalysis throws 404 for cross-user document access');

  // Insert analysis results for docId
  db.insert(analysisResults).values({
    documentId: docId,
    userId,
    documentType: 'rental_agreement',
    detectedTypeConfidence: 0.85,
    overallRiskScore: 0.65,
    riskLevel: 'medium',
    fairnessScore: 0.4,
    favorsParty: 'landlord',
    summary: 'This is a test summary.',
    keyParties: JSON.stringify(['Party A', 'Party B']),
    criticalDates: JSON.stringify(['2026-01-01']),
    keyObligations: JSON.stringify(['Pay rent', 'Maintain property']),
    missingClauses: JSON.stringify(['Force majeure']),
    jurisdictionFlags: JSON.stringify(['India']),
  }).run();

  const analysisRow = db.select().from(analysisResults).where(sql`${analysisResults.documentId} = ${docId}`).all();
  const analysisId = analysisRow[0].id;

  // Insert clauses
  db.insert(clauses).values({
    documentId: docId,
    analysisId,
    clauseNumber: 1,
    clauseTitle: 'Payment Terms',
    originalText: 'Tenant shall pay rent on the 1st of each month.',
    plainEnglishText: 'Rent is due on the 1st of each month.',
    riskLevel: 'low',
    riskScore: 0.2,
    riskReason: 'Standard payment clause.',
    riskCategory: 'payment',
    counterSuggestion: 'Consider a 5-day grace period.',
    isFlagged: false,
  }).run();

  db.insert(clauses).values({
    documentId: docId,
    analysisId,
    clauseNumber: 2,
    clauseTitle: 'Termination',
    originalText: 'Landlord may terminate with 30 days notice.',
    plainEnglishText: 'The landlord can end the lease with 30 days notice.',
    riskLevel: 'high',
    riskScore: 0.8,
    riskReason: 'Unilateral termination favors landlord.',
    riskCategory: 'termination',
    counterSuggestion: 'Add mutual termination rights.',
    isFlagged: true,
  }).run();
  persistNow();

  // 1e. getAnalysis — success with results
  const getAnalysisRes = mockRes();
  await getAnalysis(
    authedReq(userId, 'layers@test.com', { params: { documentId: String(docId) } }),
    getAnalysisRes,
    mockNext()
  );
  assert(getAnalysisRes.statusCode === 200, 'getAnalysis returns 200');
  const gaBody = getAnalysisRes.body as Record<string, unknown>;
  const gaData = gaBody.data as Record<string, unknown>;
  assert(gaData.status === 'completed', 'getAnalysis returns completed status');
  const analysisObj = gaData.analysis as Record<string, unknown>;
  assert(analysisObj.documentType === 'rental_agreement', 'getAnalysis returns correct document type');
  assert(analysisObj.overallRiskScore === 0.65, 'getAnalysis returns risk score');
  assert(Array.isArray(analysisObj.keyParties), 'getAnalysis parses keyParties as array');

  // 1f. getAnalysis — no analysis yet
  const getNoAnalysisRes = mockRes();
  await getAnalysis(
    authedReq(userId, 'layers@test.com', { params: { documentId: String(pendingDocId) } }),
    getNoAnalysisRes,
    mockNext()
  );
  const gnaBody = getNoAnalysisRes.body as Record<string, unknown>;
  const gnaData = gnaBody.data as Record<string, unknown>;
  assert(gnaData.analysis === null, 'getAnalysis returns null analysis when none exists');

  // 1g. getClauses — success
  const getClausesRes = mockRes();
  await getClauses(
    authedReq(userId, 'layers@test.com', { params: { documentId: String(docId) } }),
    getClausesRes,
    mockNext()
  );
  const gcBody = getClausesRes.body as Record<string, unknown>;
  const gcData = gcBody.data as Record<string, unknown>;
  const clauseList = gcData.clauses as Array<Record<string, unknown>>;
  assert(clauseList.length === 2, 'getClauses returns 2 clauses');
  assert(clauseList[0].clauseTitle === 'Payment Terms', 'First clause has correct title');
  assert(clauseList[1].isFlagged === 1 || clauseList[1].isFlagged === true, 'Second clause is flagged');

  // 1h. getRisks — success (empty for now, no risk items inserted)
  const getRisksRes = mockRes();
  await getRisks(
    authedReq(userId, 'layers@test.com', { params: { documentId: String(docId) } }),
    getRisksRes,
    mockNext()
  );
  const grBody = getRisksRes.body as Record<string, unknown>;
  const grData = grBody.data as Record<string, unknown>;
  const riskList = grData.riskItems as Array<Record<string, unknown>>;
  assert(Array.isArray(riskList), 'getRisks returns riskItems array');
  assert(riskList.length === 0, 'getRisks returns empty when no risk items');

  // 1i. getSummary — success
  const getSummaryRes = mockRes();
  await getSummary(
    authedReq(userId, 'layers@test.com', { params: { documentId: String(docId) } }),
    getSummaryRes,
    mockNext()
  );
  const gsBody = getSummaryRes.body as Record<string, unknown>;
  const gsData = gsBody.data as Record<string, unknown>;
  assert(gsData.summary === 'This is a test summary.', 'getSummary returns correct summary');
  assert(gsData.documentType === 'rental_agreement', 'getSummary returns document type');
  assert(gsData.riskLevel === 'medium', 'getSummary returns risk level');
  assert(gsData.fairnessScore === 0.4, 'getSummary returns fairness score');

  // 1j. Insert risk items and re-test getRisks
  db.insert(riskItems).values({
    analysisId,
    clauseId: clauseList[1].id as number,
    riskType: 'termination',
    title: 'Unilateral Termination',
    description: 'Landlord can terminate without cause.',
    severity: 'high',
    severityScore: 0.8,
    recommendation: 'Add mutual termination clause.',
  }).run();
  db.insert(riskItems).values({
    analysisId,
    riskType: 'financial',
    title: 'Late Fee Penalty',
    description: 'Excessive late fee of 10% per month.',
    severity: 'medium',
    severityScore: 0.5,
    recommendation: 'Reduce to 2% per month.',
  }).run();
  persistNow();

  const getRisksRes2 = mockRes();
  await getRisks(
    authedReq(userId, 'layers@test.com', { params: { documentId: String(docId) } }),
    getRisksRes2,
    mockNext()
  );
  const grBody2 = getRisksRes2.body as Record<string, unknown>;
  const grData2 = grBody2.data as Record<string, unknown>;
  const riskList2 = grData2.riskItems as Array<Record<string, unknown>>;
  assert(riskList2.length === 2, 'getRisks returns 2 risk items');
  assert(riskList2[0].riskType === 'termination', 'First risk item has correct type');
  assert(riskList2[1].severity === 'medium', 'Second risk item has correct severity');

  // ═══════════════════════════════════════════════════
  //  2. CHAT CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 2. Chat Controller ──');

  const { sendMessage, getHistory } = await import('../src/controllers/chatController');

  // 2a. sendMessage — success
  const sendRes = mockRes();
  await sendMessage(
    authedReq(userId, 'layers@test.com', {
      params: { documentId: String(docId) },
      body: { message: 'What are the payment terms?', sessionId: 'test-session-1' },
    }),
    sendRes,
    mockNext()
  );
  assert(sendRes.statusCode === 201, 'sendMessage returns 201');
  const sendBody = sendRes.body as Record<string, unknown>;
  assert(sendBody.success === true, 'sendMessage returns success');
  const sendData = sendBody.data as Record<string, unknown>;
  assert(sendData.sessionId === 'test-session-1', 'sendMessage returns correct sessionId');
  const msgObj = sendData.message as Record<string, unknown>;
  assert(msgObj.role === 'assistant', 'sendMessage returns assistant message');
  assert(typeof msgObj.content === 'string', 'sendMessage returns content string');

  // Verify messages stored in DB
  const chatRows = db.select().from(chatMessages).where(
    sql`${chatMessages.documentId} = ${docId} AND ${chatMessages.sessionId} = 'test-session-1'`
  ).all();
  assert(chatRows.length === 2, 'sendMessage stores user + assistant messages in DB');
  assert(chatRows[0].role === 'user', 'First DB message is user');
  assert(chatRows[1].role === 'assistant', 'Second DB message is assistant');

  // 2b. sendMessage — empty message (400)
  let emptyMsgThrew = false;
  try {
    const emptyRes = mockRes();
    await sendMessage(
      authedReq(userId, 'layers@test.com', {
        params: { documentId: String(docId) },
        body: { message: '' },
      }),
      emptyRes,
      mockNext()
    );
  } catch (e: unknown) {
    emptyMsgThrew = (e as { statusCode?: number }).statusCode === 400;
  }
  assert(emptyMsgThrew, 'sendMessage throws 400 for empty message');

  // 2c. sendMessage — document not found
  let chatDocNfThrew = false;
  try {
    const nfRes = mockRes();
    await sendMessage(
      authedReq(userId, 'layers@test.com', {
        params: { documentId: '99999' },
        body: { message: 'Hello' },
      }),
      nfRes,
      mockNext()
    );
  } catch (e: unknown) {
    chatDocNfThrew = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(chatDocNfThrew, 'sendMessage throws 404 for nonexistent document');

  // 2d. sendMessage — auto-generates sessionId
  const sendAutoRes = mockRes();
  await sendMessage(
    authedReq(userId, 'layers@test.com', {
      params: { documentId: String(docId) },
      body: { message: 'Another question' },
    }),
    sendAutoRes,
    mockNext()
  );
  const sendAutoData = (sendAutoRes.body as Record<string, unknown>).data as Record<string, unknown>;
  assert(typeof sendAutoData.sessionId === 'string' && sendAutoData.sessionId.length > 0, 'sendMessage auto-generates sessionId');

  // 2e. getHistory — success
  const histRes = mockRes();
  await getHistory(
    authedReq(userId, 'layers@test.com', {
      params: { documentId: String(docId) },
      query: { sessionId: 'test-session-1', page: '1', limit: '10' },
    }),
    histRes,
    mockNext()
  );
  assert(histRes.statusCode === 200, 'getHistory returns 200');
  const histBody = histRes.body as Record<string, unknown>;
  const histData = histBody.data as Record<string, unknown>;
  const histMessages = histData.messages as Array<Record<string, unknown>>;
  assert(histMessages.length >= 2, 'getHistory returns messages (user + assistant)');
  assert(histMessages[0].role === 'user', 'First message is user');
  assert(histMessages[1].role === 'assistant', 'Second message is assistant');
  const pagination = histData.pagination as Record<string, unknown>;
  assert(pagination.total >= 2, 'getHistory pagination total is correct');

  // 2f. getHistory — all sessions (no sessionId filter)
  const histAllRes = mockRes();
  await getHistory(
    authedReq(userId, 'layers@test.com', {
      params: { documentId: String(docId) },
      query: { page: '1', limit: '100' },
    }),
    histAllRes,
    mockNext()
  );
  const histAllData = (histAllRes.body as Record<string, unknown>).data as Record<string, unknown>;
  const allSessions = histAllData.sessions as string[];
  assert(allSessions.length >= 2, 'getHistory returns multiple session IDs');

  // 2g. getHistory — document not found
  let histNfThrew = false;
  try {
    const nfRes = mockRes();
    await getHistory(
      authedReq(userId, 'layers@test.com', {
        params: { documentId: '99999' },
      }),
      nfRes,
      mockNext()
    );
  } catch (e: unknown) {
    histNfThrew = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(histNfThrew, 'getHistory throws 404 for nonexistent document');

  // ═══════════════════════════════════════════════════
  //  3. DEADLINE CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 3. Deadline Controller ──');

  // Insert test deadlines for user 1
  db.insert(deadlines).values({
    documentId: docId,
    userId,
    title: 'Pay rent',
    description: 'Monthly rent payment',
    dueDate: '2026-02-01',
    urgencyLevel: 'high',
  }).run();

  db.insert(deadlines).values({
    documentId: docId,
    userId,
    title: 'Sign renewal',
    description: 'Lease renewal deadline',
    dueDate: '2026-06-01',
    urgencyLevel: 'medium',
  }).run();

  db.insert(deadlines).values({
    documentId: docId,
    userId,
    title: 'Completed task',
    description: 'Already done',
    dueDate: '2026-01-15',
    urgencyLevel: 'low',
    isCompleted: true,
  }).run();

  // Deadline for other user
  db.insert(deadlines).values({
    documentId: 2,
    userId: otherUserId,
    title: 'Other deadline',
    description: 'Not yours',
    dueDate: '2026-03-01',
    urgencyLevel: 'high',
  }).run();
  persistNow();

  const { listDeadlines, completeDeadline, dismissDeadline } = await import('../src/controllers/deadlineController');

  // 3a. listDeadlines — all
  const listRes = mockRes();
  await listDeadlines(authedReq(userId, 'layers@test.com'), listRes, mockNext());
  assert(listRes.statusCode === 200, 'listDeadlines returns 200');
  const listBody = listRes.body as Record<string, unknown>;
  const listData = listBody.data as Record<string, unknown>;
  const deadlineList = listData.deadlines as Array<Record<string, unknown>>;
  assert(deadlineList.length === 3, 'listDeadlines returns 3 deadlines for user');
  assert(listData.total === 3, 'listDeadlines total is 3');
  // Sorted by due date ascending
  assert(deadlineList[0].title === 'Completed task', 'listDeadlines sorted by dueDate asc (earliest first)');

  // 3b. listDeadlines — completed only
  const listCompletedRes = mockRes();
  await listDeadlines(
    authedReq(userId, 'layers@test.com', { query: { completed: 'true' } }),
    listCompletedRes,
    mockNext()
  );
  const lcBody = listCompletedRes.body as Record<string, unknown>;
  const lcData = lcBody.data as Record<string, unknown>;
  const lcList = lcData.deadlines as Array<Record<string, unknown>>;
  assert(lcList.length === 1, 'listDeadlines completed=true returns 1');
  assert(lcList[0].isCompleted === 1 || lcList[0].isCompleted === true, 'listDeadlines completed=true returns completed deadline');

  // 3c. listDeadlines — pending only
  const listPendingRes = mockRes();
  await listDeadlines(
    authedReq(userId, 'layers@test.com', { query: { completed: 'false' } }),
    listPendingRes,
    mockNext()
  );
  const lpBody = listPendingRes.body as Record<string, unknown>;
  const lpData = lpBody.data as Record<string, unknown>;
  const lpList = lpData.deadlines as Array<Record<string, unknown>>;
  assert(lpList.length === 2, 'listDeadlines completed=false returns 2');

  // 3d. completeDeadline — success
  const payRentRow = db.select().from(deadlines).where(
    sql`${deadlines.title} = 'Pay rent' AND ${deadlines.userId} = ${userId}`
  ).all();
  const payRentId = payRentRow[0].id;

  const completeRes = mockRes();
  await completeDeadline(
    authedReq(userId, 'layers@test.com', { params: { id: String(payRentId) } }),
    completeRes,
    mockNext()
  );
  assert(completeRes.statusCode === 200, 'completeDeadline returns 200');
  const compBody = completeRes.body as Record<string, unknown>;
  assert(compBody.success === true, 'completeDeadline returns success');

  // Verify in DB
  const compCheck = db.select().from(deadlines).where(sql`${deadlines.id} = ${payRentId}`).all();
  assert(compCheck[0].isCompleted === 1 || compCheck[0].isCompleted === true, 'Deadline is_completed = 1 in DB');

  // 3e. completeDeadline — not found
  let compNfThrew = false;
  try {
    const nfRes = mockRes();
    await completeDeadline(
      authedReq(userId, 'layers@test.com', { params: { id: '99999' } }),
      nfRes,
      mockNext()
    );
  } catch (e: unknown) {
    compNfThrew = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(compNfThrew, 'completeDeadline throws 404 for nonexistent deadline');

  // 3f. completeDeadline — cross-user isolation
  const otherDeadlineRow = db.select().from(deadlines).where(
    sql`${deadlines.userId} = ${otherUserId}`
  ).all();
  let compCrossThrew = false;
  try {
    const crossRes = mockRes();
    await completeDeadline(
      authedReq(userId, 'layers@test.com', { params: { id: String(otherDeadlineRow[0].id) } }),
      crossRes,
      mockNext()
    );
  } catch (e: unknown) {
    compCrossThrew = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(compCrossThrew, 'completeDeadline throws 404 for cross-user deadline');

  // 3g. dismissDeadline — success
  const signRenewalRow = db.select().from(deadlines).where(
    sql`${deadlines.title} = 'Sign renewal' AND ${deadlines.userId} = ${userId}`
  ).all();
  const signRenewalId = signRenewalRow[0].id;

  const dismissRes = mockRes();
  await dismissDeadline(
    authedReq(userId, 'layers@test.com', { params: { id: String(signRenewalId) } }),
    dismissRes,
    mockNext()
  );
  assert(dismissRes.statusCode === 200, 'dismissDeadline returns 200');

  const dismissCheck = db.select().from(deadlines).where(sql`${deadlines.id} = ${signRenewalId}`).all();
  assert(dismissCheck[0].isDismissed === 1 || dismissCheck[0].isDismissed === true, 'Deadline is_dismissed = 1 in DB');

  // 3h. dismissDeadline — not found
  let dismissNfThrew = false;
  try {
    const nfRes = mockRes();
    await dismissDeadline(
      authedReq(userId, 'layers@test.com', { params: { id: '99999' } }),
      nfRes,
      mockNext()
    );
  } catch (e: unknown) {
    dismissNfThrew = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(dismissNfThrew, 'dismissDeadline throws 404 for nonexistent deadline');

  // 3i. dismissDeadline — cross-user isolation
  let dismissCrossThrew = false;
  try {
    const crossRes = mockRes();
    await dismissDeadline(
      authedReq(userId, 'layers@test.com', { params: { id: String(otherDeadlineRow[0].id) } }),
      crossRes,
      mockNext()
    );
  } catch (e: unknown) {
    dismissCrossThrew = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(dismissCrossThrew, 'dismissDeadline throws 404 for cross-user deadline');

  // ═══════════════════════════════════════════════════
  //  4. NOTIFICATION CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 4. Notification Controller ──');

  // Insert test notifications for user 1
  db.insert(notifications).values({
    userId,
    type: 'analysis_complete',
    title: 'Analysis Ready',
    body: 'Your document has been analyzed.',
    documentId: docId,
    isRead: false,
    actionUrl: '/documents/1',
  }).run();

  db.insert(notifications).values({
    userId,
    type: 'deadline_reminder',
    title: 'Upcoming Deadline',
    body: 'Pay rent is due soon.',
    documentId: docId,
    isRead: false,
  }).run();

  db.insert(notifications).values({
    userId,
    type: 'system',
    title: 'Welcome',
    body: 'Welcome to Legisense!',
    isRead: true,
  }).run();

  // Notification for other user
  db.insert(notifications).values({
    userId: otherUserId,
    type: 'system',
    title: 'Other notification',
    body: 'Not yours.',
    isRead: false,
  }).run();
  persistNow();

  const { listNotifications, markRead, markAllRead } = await import('../src/controllers/notificationController');

  // 4a. listNotifications — success
  const notifRes = mockRes();
  await listNotifications(authedReq(userId, 'layers@test.com'), notifRes, mockNext());
  assert(notifRes.statusCode === 200, 'listNotifications returns 200');
  const notifBody = notifRes.body as Record<string, unknown>;
  const notifData = notifBody.data as Record<string, unknown>;
  const notifList = notifData.notifications as Array<Record<string, unknown>>;
  assert(notifList.length === 3, 'listNotifications returns 3 notifications for user');
  assert(notifData.unreadCount === 2, 'listNotifications unreadCount is 2');
  assert(notifData.total === 3, 'listNotifications total is 3');
  // All items present (timestamps may tie, so insertion order preserved)
  const notifTitles = notifList.map((n) => n.title);
  assert(
    notifTitles.includes('Analysis Ready') && notifTitles.includes('Upcoming Deadline') && notifTitles.includes('Welcome'),
    'listNotifications returns all 3 notification titles'
  );

  // 4b. markRead — success
  const notif1Row = db.select().from(notifications).where(
    sql`${notifications.title} = 'Analysis Ready' AND ${notifications.userId} = ${userId}`
  ).all();
  const notif1Id = notif1Row[0].id;

  const markRes = mockRes();
  await markRead(
    authedReq(userId, 'layers@test.com', { params: { id: String(notif1Id) } }),
    markRes,
    mockNext()
  );
  assert(markRes.statusCode === 200, 'markRead returns 200');

  const markCheck = db.select().from(notifications).where(sql`${notifications.id} = ${notif1Id}`).all();
  assert(markCheck[0].isRead === 1 || markCheck[0].isRead === true, 'Notification is_read = 1 after markRead');

  // 4c. markRead — not found
  let markNfThrew = false;
  try {
    const nfRes = mockRes();
    await markRead(
      authedReq(userId, 'layers@test.com', { params: { id: '99999' } }),
      nfRes,
      mockNext()
    );
  } catch (e: unknown) {
    markNfThrew = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(markNfThrew, 'markRead throws 404 for nonexistent notification');

  // 4d. markRead — cross-user isolation
  const otherNotifRow = db.select().from(notifications).where(
    sql`${notifications.userId} = ${otherUserId}`
  ).all();
  let markCrossThrew = false;
  try {
    const crossRes = mockRes();
    await markRead(
      authedReq(userId, 'layers@test.com', { params: { id: String(otherNotifRow[0].id) } }),
      crossRes,
      mockNext()
    );
  } catch (e: unknown) {
    markCrossThrew = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(markCrossThrew, 'markRead throws 404 for cross-user notification');

  // 4e. markAllRead — success
  const markAllRes = mockRes();
  await markAllRead(authedReq(userId, 'layers@test.com'), markAllRes, mockNext());
  assert(markAllRes.statusCode === 200, 'markAllRead returns 200');

  // Verify all user notifications are read
  const unreadAfter = db.select().from(notifications).where(
    sql`${notifications.userId} = ${userId} AND ${notifications.isRead} = 0`
  ).all();
  assert(unreadAfter.length === 0, 'markAllRead marks all user notifications as read');

  // Verify other user's notification is unaffected
  const otherUnread = db.select().from(notifications).where(
    sql`${notifications.userId} = ${otherUserId} AND ${notifications.isRead} = 0`
  ).all();
  assert(otherUnread.length === 1, 'markAllRead does not affect other user notifications');

  // ═══════════════════════════════════════════════════
  //  CLEANUP & SUMMARY
  // ═══════════════════════════════════════════════════
  closeDatabase();

  console.log('\n═══════════════════════════════════════════');
  const passed = results.filter((r) => r.pass).length;
  const failed = results.filter((r) => !r.pass).length;
  console.log(`\n  ${passed} passed, ${failed} failed, ${results.length} total`);
  if (failed > 0) {
    console.log('\n  Failed tests:');
    results.filter((r) => !r.pass).forEach((r) => console.log(`    ❌ ${r.test}${r.detail ? ` — ${r.detail}` : ''}`));
  }
  console.log('');
  process.exit(failed > 0 ? 1 : 0);
}

run().catch((err) => {
  console.error('Unhandled test error:', err);
  process.exit(1);
});
