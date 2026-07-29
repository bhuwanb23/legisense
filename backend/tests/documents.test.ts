import { Request, Response, NextFunction } from 'express';

import { initDatabase, getDb, closeDatabase, persistNow } from '../src/config/database';
import { sql } from 'drizzle-orm';
import { users, documents, analysisResults, clauses } from '../src/models';

import {
  listDocuments,
  getDocument,
  deleteDocument,
  uploadDocument,
} from '../src/controllers/documentController';

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

async function run() {
  console.log('🧪 Document Routes Tests\n');

  await initDatabase();
  const db = getDb();

  // Clean slate
  db.run(sql`DELETE FROM ${clauses}`);
  db.run(sql`DELETE FROM ${analysisResults}`);
  db.run(sql`DELETE FROM ${documents}`);
  db.run(sql`DELETE FROM ${users}`);
  persistNow();

  // Create test user
  db.insert(users).values({
    fullName: 'Doc Test User',
    email: 'doctest@test.com',
    passwordHash: 'hash',
    authProvider: 'email',
    isActive: true,
  }).run();

  const userRows = db.select().from(users).where(sql`${users.email} = 'doctest@test.com'`).all();
  const testUserId = userRows[0].id;

  const authedReq = (body: unknown = {}, query: unknown = {}, params: unknown = {}) =>
    mockReq({
      body,
      query,
      params,
      user: { id: testUserId, email: 'doctest@test.com', fullName: 'Doc Test User', authProvider: 'email', isActive: true },
    });

  // ═══════════════════════════════════════════════════
  //  1. DOCUMENT SCHEMAS
  // ═══════════════════════════════════════════════════
  console.log('── 1. Document Schemas ──');

  const { listDocumentsSchema, unifiedUploadSchema } = await import('../src/schemas/documentSchemas');

  const validList = listDocumentsSchema.safeParse({ page: 1, limit: 20 });
  assert(validList.success, 'listDocumentsSchema accepts defaults');

  const validListCustom = listDocumentsSchema.safeParse({ page: 2, limit: 10, status: 'completed' });
  assert(validListCustom.success, 'listDocumentsSchema accepts custom params');

  const validPaste = unifiedUploadSchema.safeParse({ sourceType: 'paste', text: 'This text must be at least fifty characters long to satisfy the minimum length requirement.' });
  assert(validPaste.success, 'unifiedUploadSchema accepts valid paste input');

  const emptyPaste = unifiedUploadSchema.safeParse({ sourceType: 'paste', text: '' });
  assert(!emptyPaste.success, 'unifiedUploadSchema rejects empty text');

  const shortPaste = unifiedUploadSchema.safeParse({ sourceType: 'paste', text: 'Too short' });
  assert(!shortPaste.success, 'unifiedUploadSchema rejects text under 50 chars');

  const validUrl = unifiedUploadSchema.safeParse({ sourceType: 'url', url: 'https://example.com' });
  assert(validUrl.success, 'unifiedUploadSchema accepts valid URL');

  const invalidUrl = unifiedUploadSchema.safeParse({ sourceType: 'url', url: 'ftp://bad.com' });
  assert(!invalidUrl.success, 'unifiedUploadSchema rejects non-http URL');

  const validFile = unifiedUploadSchema.safeParse({ sourceType: 'file' });
  assert(validFile.success, 'unifiedUploadSchema accepts file source_type');

  const validScan = unifiedUploadSchema.safeParse({ sourceType: 'scan', title: 'Scan of contract' });
  assert(validScan.success, 'unifiedUploadSchema accepts scan with title');

  const badSourceType = unifiedUploadSchema.safeParse({ sourceType: 'invalid' });
  assert(!badSourceType.success, 'unifiedUploadSchema rejects unknown source_type');

  // ═══════════════════════════════════════════════════
  //  2. PASTE TEXT VIA UNIFIED UPLOAD
  // ═══════════════════════════════════════════════════
  console.log('\n── 2. Paste Text via Unified Upload ──');

  const pasteRes = mockRes();
  await uploadDocument(
    authedReq({ sourceType: 'paste', text: 'This is a pasted legal agreement between Party A and Party B that satisfies the minimum character requirement for paste.', title: 'Test Agreement' }),
    pasteRes,
    mockNext()
  );

  assert(pasteRes.statusCode === 202, 'Paste returns 202');
  const pasteBody = pasteRes.body as Record<string, unknown>;
  assert(pasteBody.success === true, 'Paste returns success');
  const pasteData = pasteBody.data as Record<string, unknown>;
  assert(typeof pasteData.documentId === 'number', 'Paste returns documentId');
  assert(pasteData.sourceType === 'paste', 'Paste has sourceType paste');
  assert(pasteData.fileFormat === 'txt', 'Paste has fileFormat txt');

  const pasteDocId = pasteData.documentId as number;

  // Verify in DB
  const pasteDocRows = db.select().from(documents).where(sql`${documents.id} = ${pasteDocId}`).all();
  assert(pasteDocRows.length === 1, 'Paste document created in DB');
  assert(pasteDocRows[0].sourceType === 'paste', 'DB has sourceType paste');
  assert(pasteDocRows[0].rawText === 'This is a pasted legal agreement between Party A and Party B that satisfies the minimum character requirement for paste.', 'DB has rawText');
  assert(pasteDocRows[0].storagePath === '', 'Paste does not store to disk');

  // Paste without title
  const pasteRes2 = mockRes();
  await uploadDocument(
    authedReq({ sourceType: 'paste', text: 'Another pasted document that is long enough to meet the fifty character minimum threshold for paste submissions.' }),
    pasteRes2,
    mockNext()
  );
  assert(pasteRes2.statusCode === 202, 'Paste without title returns 202');
  const pasteData2 = (pasteRes2.body as Record<string, unknown>).data as Record<string, unknown>;
  assert(pasteData2.originalName === 'Pasted Text', 'Default title is Pasted Text');

  // ═══════════════════════════════════════════════════
  //  3. LIST DOCUMENTS CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 3. List Documents Controller ──');

  const listRes = mockRes();
  await listDocuments(authedReq({}, { page: 1, limit: 10 }), listRes, mockNext());

  assert(listRes.statusCode === 200, 'List returns 200');
  const listBody = listRes.body as Record<string, unknown>;
  assert(listBody.success === true, 'List returns success');
  const listData = listBody.data as Record<string, unknown>;
  assert(Array.isArray(listData.documents), 'List returns documents array');
  assert((listData.documents as unknown[]).length >= 2, 'List finds at least 2 documents');

  const pagination = listData.pagination as Record<string, unknown>;
  assert(typeof pagination.page === 'number', 'Pagination has page');
  assert(typeof pagination.total === 'number', 'Pagination has total');
  assert(typeof pagination.totalPages === 'number', 'Pagination has totalPages');

  // Filter by status
  const listFiltered = mockRes();
  await listDocuments(authedReq({}, { status: 'pending' }), listFiltered, mockNext());
  const filteredData = (listFiltered.body as Record<string, unknown>).data as Record<string, unknown>;
  const filteredDocs = filteredData.documents as Array<Record<string, unknown>>;
  assert(filteredDocs.every((d) => d.processingStatus === 'pending'), 'Filtered results have correct status');

  // ═══════════════════════════════════════════════════
  //  4. GET DOCUMENT CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 4. Get Document Controller ──');

  const getRes = mockRes();
  await getDocument(authedReq({}, {}, { id: String(pasteDocId) }), getRes, mockNext());

  assert(getRes.statusCode === 200, 'Get returns 200');
  const getBody = getRes.body as Record<string, unknown>;
  assert(getBody.success === true, 'Get returns success');
  const getData = getBody.data as Record<string, unknown>;
  assert(getData.id === pasteDocId, 'Get returns correct document');
  assert(getData.originalName === 'Test Agreement', 'Get has correct originalName');
  assert(getData.sourceType === 'paste', 'Get has sourceType paste');

  // Non-existent document
  let notFoundThrew = false;
  try {
    await getDocument(authedReq({}, {}, { id: '999999' }), mockRes(), mockNext());
  } catch (e: unknown) {
    notFoundThrew = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(notFoundThrew, 'Get throws 404 for non-existent document');

  // ═══════════════════════════════════════════════════
  //  5. DELETE DOCUMENT CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 5. Delete Document Controller ──');

  const delRes = mockRes();
  await deleteDocument(authedReq({}, {}, { id: String(pasteDocId) }), delRes, mockNext());

  assert(delRes.statusCode === 200, 'Delete returns 200');
  const delBody = delRes.body as Record<string, unknown>;
  assert(delBody.success === true, 'Delete returns success');

  // Verify soft-deleted in DB
  const deletedDoc = db.select().from(documents).where(sql`${documents.id} = ${pasteDocId}`).all();
  assert(deletedDoc.length === 1, 'Document still exists in DB');
  assert((deletedDoc[0] as { isDeleted: boolean }).isDeleted === true, 'Document is soft-deleted');

  // Get should not return deleted document
  let deletedNotFound = false;
  try {
    await getDocument(authedReq({}, {}, { id: String(pasteDocId) }), mockRes(), mockNext());
  } catch (e: unknown) {
    deletedNotFound = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(deletedNotFound, 'Get returns 404 for deleted document');

  // Delete non-existent
  let delNotFound = false;
  try {
    await deleteDocument(authedReq({}, {}, { id: '999999' }), mockRes(), mockNext());
  } catch (e: unknown) {
    delNotFound = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(delNotFound, 'Delete throws 404 for non-existent document');

  // ═══════════════════════════════════════════════════
  //  6. UNAUTHORIZED ACCESS
  // ═══════════════════════════════════════════════════
  console.log('\n── 6. Unauthorized Access ──');

  // Create a second user's document
  db.insert(users).values({
    fullName: 'Other User',
    email: 'other@test.com',
    passwordHash: 'hash',
    authProvider: 'email',
    isActive: true,
  }).run();

  const otherUser = db.select().from(users).where(sql`${users.email} = 'other@test.com'`).all()[0];

  db.insert(documents).values({
    userId: otherUser.id,
    originalName: 'Other Doc',
    storagePath: 'other-doc.txt',
    fileFormat: 'txt',
    fileSize: 100,
    sourceType: 'file',
    uploadStatus: 'uploaded',
    processingStatus: 'completed',
  }).run();

  const otherDoc = db.select().from(documents).where(sql`${documents.userId} = ${otherUser.id}`).all()[0];

  // User 1 tries to access User 2's document
  let crossUserNotFound = false;
  try {
    await getDocument(authedReq({}, {}, { id: String(otherDoc.id) }), mockRes(), mockNext());
  } catch (e: unknown) {
    crossUserNotFound = (e as { statusCode?: number }).statusCode === 404;
  }
  assert(crossUserNotFound, 'Cannot access other user document (returns 404)');

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
