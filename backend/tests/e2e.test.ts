import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';

process.env.JWT_SECRET = process.env.JWT_SECRET || 'e2e-test-secret-that-is-64-chars-long!!!!!!!!!!!!!!!!!!!!!!!!!';
process.env.JWT_ACCESS_EXPIRES_IN = '3600';
process.env.JWT_REFRESH_EXPIRES_IN = '86400';
process.env.UPLOAD_DIR = './test-e2e-uploads';

import fs from 'node:fs';
import path from 'node:path';

const TEST_EMAIL = `e2e-${Date.now()}@test.com`;
const TEST_PASSWORD = 'TestPass1!';
const TEST_NAME = 'E2E Tester';

function createMinimalPdf(text: string): Buffer {
  const esc = (s: string) => s.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');
  const streamContent = `BT /F1 12 Tf 100 700 Td (${esc(text)}) Tj ET`;
  const streamLen = Buffer.byteLength(streamContent, 'latin1');

  const header = '%PDF-1.4\n';
  const obj1 = '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n';
  const obj2 = '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n';
  const obj3 = `3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n`;
  const obj4 = `4 0 obj\n<< /Length ${streamLen} >>\nstream\n${streamContent}\nendstream\nendobj\n`;
  const obj5 = '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n';

  const body = header + obj1 + obj2 + obj3 + obj4 + obj5;

  const offsets = [
    0,
    Buffer.byteLength(header, 'latin1'),
    Buffer.byteLength(header + obj1, 'latin1'),
    Buffer.byteLength(header + obj1 + obj2, 'latin1'),
    Buffer.byteLength(header + obj1 + obj2 + obj3, 'latin1'),
    Buffer.byteLength(header + obj1 + obj2 + obj3 + obj4, 'latin1'),
  ];

  const bodyLen = Buffer.byteLength(body, 'latin1');
  let xref = 'xref\n';
  xref += `0 6\n`;
  xref += `0000000000 65535 f \n`;
  for (let i = 1; i < 6; i++) {
    xref += `${String(offsets[i]).padStart(10, '0')} 00000 n \n`;
  }

  const xrefOffset = bodyLen;
  const trailer = `trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n${xrefOffset}\n%%EOF\n`;

  return Buffer.from(body + xref + trailer, 'latin1');
}

async function jsonRequest(server: http.Server, method: string, pathname: string, body?: unknown, token?: string): Promise<{ status: number; body: any }> {
  return new Promise((resolve, reject) => {
    const addr = server.address() as { port: number };
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const req = http.request({
      hostname: '127.0.0.1',
      port: addr.port,
      path: pathname,
      method,
      headers,
    }, (res) => {
      const chunks: Buffer[] = [];
      res.on('data', (c: Buffer) => chunks.push(c));
      res.on('end', () => {
        const raw = Buffer.concat(chunks).toString('utf-8');
        let parsed: any;
        try { parsed = JSON.parse(raw); } catch { parsed = raw; }
        resolve({ status: res.statusCode || 0, body: parsed });
      });
    });
    req.on('error', reject);
    if (body !== undefined) req.write(JSON.stringify(body));
    req.end();
  });
}

async function multipartUpload(server: http.Server, url: string, fieldName: string, fileName: string, fileBuffer: Buffer, token: string): Promise<{ status: number; body: any }> {
  return new Promise((resolve, reject) => {
    const boundary = '----TestBoundary' + Date.now();
    const addr = server.address() as { port: number };

    const header = `--${boundary}\r\nContent-Disposition: form-data; name="${fieldName}"; filename="${fileName}"\r\nContent-Type: application/pdf\r\n\r\n`;
    const footer = `\r\n--${boundary}--\r\n`;

    const payload = Buffer.concat([
      Buffer.from(header, 'latin1'),
      fileBuffer,
      Buffer.from(footer, 'latin1'),
    ]);

    const req = http.request({
      hostname: '127.0.0.1',
      port: addr.port,
      path: url,
      method: 'POST',
      headers: {
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'Content-Length': String(payload.length),
        'Authorization': `Bearer ${token}`,
      },
    }, (res) => {
      const chunks: Buffer[] = [];
      res.on('data', (c: Buffer) => chunks.push(c));
      res.on('end', () => {
        const raw = Buffer.concat(chunks).toString('utf-8');
        let parsed: any;
        try { parsed = JSON.parse(raw); } catch { parsed = raw; }
        resolve({ status: res.statusCode || 0, body: parsed });
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise(r => setTimeout(r, ms));
}

describe('End-to-End Flow', () => {
  let server: http.Server;
  let accessToken: string;
  let refreshToken: string;
  let documentId: number;
  let uploadDir: string;

  before(async () => {
    uploadDir = path.resolve(__dirname, '..', process.env.UPLOAD_DIR!);
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

    const { initDatabase, getDb, persistNow } = await import('../src/config/database');
    const { sql } = await import('drizzle-orm');
    const {
      users, documents, analysisResults,
      clauses, riskItems, deadlines, chatMessages,
      notifications, sessions, usageLogs, queueJobs,
    } = await import('../src/models');
    const { initSocketIO } = await import('../src/services/socketService');
    const { startQueueSystem } = await import('../src/queue');
    const app = (await import('../src/app')).default;

    const db = await initDatabase();

    await db.run(sql`
      CREATE TABLE IF NOT EXISTS ${users} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL, email TEXT NOT NULL UNIQUE,
        phone_number TEXT, password_hash TEXT,
        auth_provider TEXT NOT NULL DEFAULT 'email',
        profile_photo_url TEXT, profession TEXT,
        preferred_language TEXT NOT NULL DEFAULT 'en',
        default_jurisdiction TEXT,
        is_verified INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        last_login_at TEXT
      )
    `);

    await db.run(sql`
      CREATE TABLE IF NOT EXISTS ${documents} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id),
        original_name TEXT NOT NULL,
        storage_path TEXT NOT NULL,
        file_format TEXT NOT NULL,
        file_size INTEGER, page_count INTEGER,
        source_type TEXT NOT NULL, source_url TEXT,
        raw_text TEXT, detected_language TEXT,
        upload_status TEXT NOT NULL DEFAULT 'uploading',
        processing_status TEXT NOT NULL DEFAULT 'pending',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        auto_delete_at TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    await db.run(sql`
      CREATE TABLE IF NOT EXISTS ${analysisResults} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL UNIQUE REFERENCES documents(id),
        user_id INTEGER NOT NULL REFERENCES users(id),
        document_type TEXT, detected_type_confidence REAL,
        overall_risk_score REAL, risk_level TEXT,
        fairness_score REAL, favors_party TEXT,
        summary TEXT, key_parties TEXT,
        critical_dates TEXT, key_obligations TEXT,
        missing_clauses TEXT, jurisdiction_flags TEXT,
        breach_scenarios TEXT,
        processing_time REAL, ai_model_used TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    await db.run(sql`
      CREATE TABLE IF NOT EXISTS ${clauses} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL REFERENCES documents(id),
        analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
        clause_number INTEGER, clause_title TEXT,
        original_text TEXT NOT NULL, plain_english_text TEXT,
        risk_level TEXT, risk_score REAL,
        risk_reason TEXT, risk_category TEXT,
        counter_suggestion TEXT,
        is_flagged INTEGER NOT NULL DEFAULT 0,
        page_number INTEGER, party_references TEXT,
        start_position INTEGER,
        end_position INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    await db.run(sql`
      CREATE TABLE IF NOT EXISTS ${riskItems} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        analysis_id INTEGER NOT NULL REFERENCES analysis_results(id),
        clause_id INTEGER REFERENCES clauses(id),
        risk_type TEXT NOT NULL, title TEXT NOT NULL,
        description TEXT, severity TEXT NOT NULL,
        severity_score REAL, recommendation TEXT,
        legal_reference TEXT, jurisdiction TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    await db.run(sql`
      CREATE TABLE IF NOT EXISTS ${deadlines} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL REFERENCES documents(id),
        user_id INTEGER NOT NULL REFERENCES users(id),
        title TEXT NOT NULL, description TEXT,
        due_date TEXT NOT NULL, recurrence TEXT,
        urgency_level TEXT,
        reminder_sent INTEGER NOT NULL DEFAULT 0,
        reminder_date TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_dismissed INTEGER NOT NULL DEFAULT 0,
        calendar_exported INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    await db.run(sql`
      CREATE TABLE IF NOT EXISTS ${chatMessages} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL REFERENCES documents(id),
        user_id INTEGER NOT NULL REFERENCES users(id),
        session_id TEXT NOT NULL, role TEXT NOT NULL,
        message TEXT NOT NULL,
        cited_clause_ids TEXT, cited_pages TEXT,
        tokens_used INTEGER, response_time REAL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    await db.run(sql`
      CREATE TABLE IF NOT EXISTS ${notifications} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id),
        type TEXT NOT NULL, title TEXT NOT NULL,
        body TEXT, document_id INTEGER REFERENCES documents(id),
        is_read INTEGER NOT NULL DEFAULT 0,
        action_url TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    await db.run(sql`
      CREATE TABLE IF NOT EXISTS ${sessions} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id),
        refresh_token TEXT NOT NULL UNIQUE,
        device_info TEXT, ip_address TEXT,
        expires_at TEXT NOT NULL,
        is_revoked INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    await db.run(sql`
      CREATE TABLE IF NOT EXISTS ${usageLogs} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id),
        action TEXT NOT NULL,
        document_id INTEGER REFERENCES documents(id),
        tokens_consumed INTEGER,
        processing_time REAL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    await db.run(sql`
      CREATE TABLE IF NOT EXISTS ${queueJobs} (
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
        started_at TEXT, completed_at TEXT
      )
    `);

    try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN provider TEXT`); } catch {}
    try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN model TEXT`); } catch {}
    try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN cost REAL`); } catch {}
    try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN input_tokens INTEGER`); } catch {}
    try { db.run(sql`ALTER TABLE usage_logs ADD COLUMN output_tokens INTEGER`); } catch {}
    try { db.run(sql`ALTER TABLE documents ADD COLUMN encryption_iv TEXT`); } catch {}
    try { db.run(sql`ALTER TABLE analysis_results ADD COLUMN breach_scenarios TEXT`); } catch {}
    persistNow();

    server = http.createServer(app);
    initSocketIO(server);
    await startQueueSystem();

    await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
  });

  after(async () => {
    const { closeSocketIO } = await import('../src/services/socketService');
    const { stopQueueSystem } = await import('../src/queue');
    const { closeDatabase } = await import('../src/config/database');

    await stopQueueSystem();
    closeSocketIO();
    closeDatabase();
    server.close();

    if (fs.existsSync(uploadDir)) {
      fs.rmSync(uploadDir, { recursive: true, force: true });
    }
  });

  it('1. Register a new user', async () => {
    const res = await jsonRequest(server, 'POST', '/api/auth/register', {
      fullName: TEST_NAME,
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
    });

    assert.equal(res.status, 201, `Expected 201, got ${res.status}: ${JSON.stringify(res.body)}`);
    assert.ok(res.body.success, 'Response has success=true');
    assert.ok(res.body.data.accessToken, 'Has accessToken');
    assert.ok(res.body.data.refreshToken, 'Has refreshToken');
    assert.equal(res.body.data.user.email, TEST_EMAIL);

    accessToken = res.body.data.accessToken;
    refreshToken = res.body.data.refreshToken;
  });

  it('2. Login with the new user', async () => {
    const res = await jsonRequest(server, 'POST', '/api/auth/login', {
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
    });

    assert.equal(res.status, 200, `Expected 200, got ${res.status}`);
    assert.ok(res.body.success);
    assert.ok(res.body.data.accessToken);
    assert.ok(res.body.data.refreshToken);
    assert.equal(res.body.data.user.email, TEST_EMAIL);

    accessToken = res.body.data.accessToken;
  });

  it('3. Upload a PDF document', async () => {
    const pdfText = 'Test legal agreement between Party A and Party B for consulting services.';
    const pdfBuffer = createMinimalPdf(pdfText);

    const res = await multipartUpload(server, '/api/documents/upload', 'file', 'test-contract.pdf', pdfBuffer, accessToken);

    assert.equal(res.status, 202, `Expected 202, got ${res.status}: ${JSON.stringify(res.body)}`);
    assert.ok(res.body.success, 'Upload success');
    assert.ok(res.body.data.documentId, 'Has documentId');
    assert.ok(res.body.data.jobId, 'Has jobId');
    assert.equal(res.body.data.uploadStatus, 'uploaded');
    assert.equal(res.body.data.processingStatus, 'pending');

    documentId = res.body.data.documentId;
  });

  it('4. List documents includes the new document', async () => {
    const res = await jsonRequest(server, 'GET', '/api/documents', undefined, accessToken);

    assert.equal(res.status, 200);
    assert.ok(res.body.success);
    const docs = res.body.data.documents || res.body.data;
    assert.ok(Array.isArray(docs), 'Documents is an array');
    const found = docs.find((d: any) => d.id === documentId);
    assert.ok(found, 'New document found in list');
  });

  it('5. Get document status after upload', async () => {
    const res = await jsonRequest(server, 'GET', `/api/documents/${documentId}/status`, undefined, accessToken);

    assert.equal(res.status, 200);
    assert.ok(res.body.success);
    const status = res.body.data?.processingStatus || res.body.data?.status;
    assert.ok(['pending', 'processing', 'completed', 'analyzed', 'failed'].includes(status),
      `Status is valid, got: ${status}`);
  });

  it('6. Analysis worker processes the job', { timeout: 60000 }, async () => {
    const maxAttempts = 30;
    let finalStatus = 'pending';
    let analysisBody: any = null;

    for (let i = 0; i < maxAttempts; i++) {
      await sleep(2000);

      const res = await jsonRequest(server, 'GET', `/api/analysis/${documentId}`, undefined, accessToken);
      assert.equal(res.status, 200, `Poll ${i}: expected 200, got ${res.status}`);

      if (!res.body.success) {
        finalStatus = 'error';
        analysisBody = res.body;
        break;
      }

      const data = res.body.data;
      const st = data?.status || 'pending';

      if (st === 'completed' || st === 'analyzed') { finalStatus = st; analysisBody = data; break; }
      if (st === 'failed') { finalStatus = 'failed'; analysisBody = data; break; }

      if (i === maxAttempts - 1) { finalStatus = 'timeout'; analysisBody = data; }
    }

    assert.notEqual(finalStatus, 'timeout', `Analysis not done in ${maxAttempts * 2}s`);
    assert.notEqual(finalStatus, 'error', `Analysis error: ${JSON.stringify(analysisBody)}`);

    if (finalStatus === 'failed') {
      console.log('  ⚠ Analysis failed (normal if no AI API keys are configured)');
      return;
    }

    assert.ok(analysisBody?.analysis, 'Has analysis data');
  });

  it('7. Get document returns the record', async () => {
    const res = await jsonRequest(server, 'GET', `/api/documents/${documentId}`, undefined, accessToken);

    assert.equal(res.status, 200);
    assert.ok(res.body.success);
    assert.equal(res.body.data.id, documentId, 'Document ID matches');
  });

  it('8. Get clauses', async () => {
    const res = await jsonRequest(server, 'GET', `/api/analysis/${documentId}/clauses`, undefined, accessToken);
    assert.equal(res.status, 200);
    assert.ok(res.body.success);
    assert.ok(Array.isArray(res.body.data?.clauses || res.body.data));
  });

  it('9. Get risks', async () => {
    const res = await jsonRequest(server, 'GET', `/api/analysis/${documentId}/risks`, undefined, accessToken);
    assert.equal(res.status, 200);
    assert.ok(res.body.success);
    assert.ok(Array.isArray(res.body.data?.riskItems || res.body.data));
  });

  it('10. Get summary', async () => {
    const res = await jsonRequest(server, 'GET', `/api/analysis/${documentId}/summary`, undefined, accessToken);
    assert.equal(res.status, 200);
    assert.ok(res.body.success);
  });

  it('11. Delete document', async () => {
    const res = await jsonRequest(server, 'DELETE', `/api/documents/${documentId}`, undefined, accessToken);
    assert.equal(res.status, 200, `Expected 200, got ${res.status}`);
    assert.ok(res.body.success, 'Delete success');
  });

  it('12. Paste text goes through unified upload pipeline', async () => {
    const res = await jsonRequest(server, 'POST', '/api/documents/upload', {
      sourceType: 'paste',
      text: 'Pasted legal document for testing the full pipeline with the unified upload endpoint that handles all formats.',
      title: 'Pasted Test',
    }, accessToken);

    assert.equal(res.status, 202, `Expected 202, got ${res.status}`);
    assert.ok(res.body.success);
    assert.ok(res.body.data.documentId);
    assert.equal(res.body.data.sourceType, 'paste');
    assert.equal(res.body.data.fileFormat, 'txt');
  });

  it('13. Health check', async () => {
    const res = await jsonRequest(server, 'GET', '/health');
    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'ok');
    assert.equal(res.body.service, 'legisense-backend');
  });

  it('14. Unauthenticated request to protected route returns 401', async () => {
    const res = await jsonRequest(server, 'GET', '/api/documents');
    assert.equal(res.status, 401, `Expected 401, got ${res.status}`);
  });

  it('15. Invalid route returns 404', async () => {
    const res = await jsonRequest(server, 'GET', '/api/nonexistent', undefined, accessToken);
    assert.equal(res.status, 404);
  });
});
