/* Comprehensive end-to-end test suite against the deployed Render backend.
 * Uses Node 24 native fetch + FormData/Blob. No external deps.
 * Run: node tests/e2e-deployed.mjs
 */
const BASE = process.env.E2E_BASE || 'https://legisense-kr6z.onrender.com';

const results = [];
let pass = 0, fail = 0, warn = 0;

const uniq = Date.now().toString(36);
const EMAIL = `e2e-${uniq}@test.com`;
const PASSWORD = 'TestPass1!Complex';
const NAME = 'E2E Deployed Tester';

let accessToken = null;
let refreshToken = null;
let documentId = null;
let apiKey = null;

function rec(name, status, ok, detail) {
  results.push({ name, status, ok, detail });
  if (ok === true || (ok && ok !== 'warn')) pass++;
  else if (ok === 'warn') warn++;
  else fail++;
  const icon = (ok === true || (ok && ok !== 'warn')) ? 'PASS' : ok === 'warn' ? 'WARN' : 'FAIL';
  console.log(`[${icon}] ${name} -> ${status}${detail ? ' | ' + detail : ''}`);
}

async function req(method, path, { body, token, headers = {}, raw = false, form } = {}) {
  const h = { ...headers };
  if (token) h['Authorization'] = `Bearer ${token}`;
  let payload;
  if (form) {
    payload = form; // FormData sets its own content-type
  } else if (body !== undefined) {
    h['Content-Type'] = 'application/json';
    payload = JSON.stringify(body);
  }
  const res = await fetch(BASE + path, { method, headers: h, body: payload });
  const text = await res.text();
  let json;
  try { json = JSON.parse(text); } catch { json = text; }
  return { status: res.status, body: json, text };
}

function snippet(v, n = 160) {
  const s = typeof v === 'string' ? v : JSON.stringify(v);
  return (s || '').slice(0, n).replace(/\s+/g, ' ');
}

// Minimal valid PDF generator
function makePdf(text) {
  const esc = (s) => s.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');
  const stream = `BT /F1 12 Tf 72 720 Td (${esc(text)}) Tj ET`;
  const len = Buffer.byteLength(stream, 'latin1');
  const header = '%PDF-1.4\n';
  const o1 = '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n';
  const o2 = '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n';
  const o3 = '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n';
  const o4 = `4 0 obj\n<< /Length ${len} >>\nstream\n${stream}\nendstream\nendobj\n`;
  const o5 = '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n';
  const body = header + o1 + o2 + o3 + o4 + o5;
  const offsets = [0];
  let acc = header;
  for (const o of [o1, o2, o3, o4]) { offsets.push(Buffer.byteLength(acc, 'latin1')); acc += o; }
  const bodyLen = Buffer.byteLength(body, 'latin1');
  let xref = 'xref\n0 6\n0000000000 65535 f \n';
  for (let i = 1; i < 6; i++) xref += `${String(offsets[i]).padStart(10, '0')} 00000 n \n`;
  const trailer = `trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n${bodyLen}\n%%EOF\n`;
  return Buffer.from(body + xref + trailer, 'latin1');
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  console.log(`\n=== E2E against ${BASE} ===\n`);

  // ---------- 0. Health ----------
  {
    const r = await req('GET', '/health');
    rec('GET /health', r.status, r.status === 200 && r.body.status === 'ok', snippet(r.body));
  }

  // ---------- 1. Auth ----------
  {
    const r = await req('POST', '/api/auth/register', { body: { fullName: NAME, email: EMAIL, password: PASSWORD } });
    const ok = r.status === 201 && r.body.success && r.body.data?.accessToken;
    rec('POST /api/auth/register', r.status, ok, snippet(r.body));
    if (ok) { accessToken = r.body.data.accessToken; refreshToken = r.body.data.refreshToken; }
  }
  {
    const r = await req('POST', '/api/auth/login', { body: { email: EMAIL, password: PASSWORD } });
    const ok = r.status === 200 && r.body.data?.accessToken;
    rec('POST /api/auth/login', r.status, ok, snippet(r.body));
    if (ok) { accessToken = r.body.data.accessToken; refreshToken = r.body.data.refreshToken; }
  }
  {
    const r = await req('POST', '/api/auth/login', { body: { email: EMAIL, password: 'WrongPass1!' } });
    rec('POST /api/auth/login (bad password)', r.status, r.status === 401 || r.status === 400, snippet(r.body));
  }
  {
    const r = await req('POST', '/api/auth/refresh-token', { body: { refreshToken } });
    const ok = r.status === 200 && r.body.data?.accessToken;
    rec('POST /api/auth/refresh-token', r.status, ok, snippet(r.body));
    if (ok) accessToken = r.body.data.accessToken;
  }
  {
    const r = await req('POST', '/api/auth/forgot-password', { body: { email: EMAIL } });
    rec('POST /api/auth/forgot-password', r.status, r.status === 200 || r.status === 202, snippet(r.body));
  }

  // ---------- 2. Users / profile ----------
  {
    const r = await req('GET', '/api/users/profile', { token: accessToken });
    rec('GET /api/users/profile', r.status, r.status === 200 && r.body.success, snippet(r.body));
  }
  {
    const r = await req('PUT', '/api/users/profile', { token: accessToken, body: { fullName: 'E2E Updated Name', profession: 'QA Engineer' } });
    rec('PUT /api/users/profile', r.status, r.status === 200, snippet(r.body));
  }
  {
    const r = await req('PUT', '/api/users/preferences', { token: accessToken, body: { preferredLanguage: 'en', defaultJurisdiction: 'US-CA' } });
    rec('PUT /api/users/preferences', r.status, r.status === 200, snippet(r.body));
  }
  {
    const r = await req('GET', '/api/users/profile'); // no token
    rec('GET /api/users/profile (no auth)', r.status, r.status === 401, snippet(r.body));
  }

  // ---------- 3. API keys ----------
  {
    const r = await req('POST', '/api/users/api-keys', { token: accessToken, body: { name: 'e2e-key' } });
    const ok = r.status === 200 || r.status === 201;
    rec('POST /api/users/api-keys', r.status, ok, snippet(r.body));
    const key = r.body?.data?.apiKey || r.body?.data?.key || r.body?.data?.token;
    if (key) apiKey = key;
  }
  {
    const r = await req('GET', '/api/users/api-keys', { token: accessToken });
    rec('GET /api/users/api-keys', r.status, r.status === 200, snippet(r.body));
  }

  // ---------- 4. Document upload (multipart) ----------
  {
    const pdfText = 'SERVICE AGREEMENT. This Agreement is entered into between Acme Corporation ("Provider") and Beta Industries ("Client"). ' +
      'Provider shall deliver consulting services. Client shall pay $50,000 within 30 days of invoice. ' +
      'Either party may terminate this Agreement upon 60 days written notice. ' +
      'This Agreement is governed by the laws of the State of California. ' +
      'Limitation of liability shall not exceed the fees paid in the preceding 12 months. ' +
      'Confidential information shall be protected for a period of 5 years.';
    const pdf = makePdf(pdfText);
    const form = new FormData();
    form.append('file', new Blob([pdf], { type: 'application/pdf' }), 'e2e-contract.pdf');
    const r = await req('POST', '/api/documents/upload', { token: accessToken, form });
    const ok = (r.status === 202 || r.status === 201 || r.status === 200) && r.body.data?.documentId;
    rec('POST /api/documents/upload (pdf)', r.status, ok, snippet(r.body));
    if (ok) documentId = r.body.data.documentId;
  }

  // ---------- 5. Documents list/get/status ----------
  {
    const r = await req('GET', '/api/documents', { token: accessToken });
    rec('GET /api/documents', r.status, r.status === 200, snippet(r.body));
  }
  if (documentId) {
    {
      const r = await req('GET', `/api/documents/${documentId}`, { token: accessToken });
      rec('GET /api/documents/:id', r.status, r.status === 200, snippet(r.body));
    }
    {
      const r = await req('GET', `/api/documents/${documentId}/status`, { token: accessToken });
      rec('GET /api/documents/:id/status', r.status, r.status === 200, snippet(r.body));
    }
  }

  // ---------- 6. Analysis ----------
  {
    const r = await req('GET', '/api/analysis/templates', { token: accessToken });
    rec('GET /api/analysis/templates', r.status, r.status === 200, snippet(r.body));
  }
  if (documentId) {
    {
      const r = await req('POST', `/api/analysis/start/${documentId}`, { token: accessToken, body: {} });
      // AI may not be configured on Render; accept 200/202 (queued) or a clean 4xx/5xx, but not a crash
      const ok = r.status < 500;
      rec('POST /api/analysis/start/:id', r.status, ok ? (r.status === 200 || r.status === 202 ? true : 'warn') : false, snippet(r.body));
    }
    // Give the worker a moment to pick up the job
    await sleep(3000);
    {
      const r = await req('GET', `/api/analysis/${documentId}`, { token: accessToken });
      rec('GET /api/analysis/:id', r.status, r.status === 200 || r.status === 404, snippet(r.body));
    }
    {
      const r = await req('GET', `/api/analysis/${documentId}/clauses`, { token: accessToken });
      rec('GET /api/analysis/:id/clauses', r.status, r.status === 200 || r.status === 404, snippet(r.body));
    }
    {
      const r = await req('GET', `/api/analysis/${documentId}/risks`, { token: accessToken });
      rec('GET /api/analysis/:id/risks', r.status, r.status === 200 || r.status === 404, snippet(r.body));
    }
    {
      const r = await req('GET', `/api/analysis/${documentId}/summary`, { token: accessToken });
      rec('GET /api/analysis/:id/summary', r.status, r.status === 200 || r.status === 404, snippet(r.body));
    }
    {
      const r = await req('GET', `/api/analysis/${documentId}/risk-dashboard`, { token: accessToken });
      rec('GET /api/analysis/:id/risk-dashboard', r.status, r.status === 200 || r.status === 404, snippet(r.body));
    }
    {
      const r = await req('GET', `/api/analysis/${documentId}/plain-english`, { token: accessToken });
      rec('GET /api/analysis/:id/plain-english', r.status, r.status === 200 || r.status === 404, snippet(r.body));
    }
    {
      const r = await req('GET', `/api/analysis/${documentId}/missing-clauses`, { token: accessToken });
      rec('GET /api/analysis/:id/missing-clauses', r.status, r.status === 200 || r.status === 404, snippet(r.body));
    }
    {
      const r = await req('GET', `/api/analysis/${documentId}/counter-clauses`, { token: accessToken });
      rec('GET /api/analysis/:id/counter-clauses', r.status, r.status === 200 || r.status === 404, snippet(r.body));
    }
    {
      const r = await req('GET', `/api/analysis/${documentId}/classify`, { token: accessToken });
      rec('GET /api/analysis/:id/classify', r.status, r.status < 500, snippet(r.body));
    }
  }

  // ---------- 7. Chat ----------
  if (documentId) {
    let sessionId = null;
    {
      const r = await req('POST', `/api/chat/${documentId}/session`, { token: accessToken, body: {} });
      const ok = r.status === 200 || r.status === 201;
      rec('POST /api/chat/:id/session', r.status, ok, snippet(r.body));
      sessionId = r.body?.data?.sessionId || r.body?.data?.session_id;
    }
    {
      const r = await req('POST', `/api/chat/${documentId}/message`, { token: accessToken, body: { sessionId, message: 'What is the termination notice period?' } });
      rec('POST /api/chat/:id/message', r.status, r.status < 500, snippet(r.body));
    }
    {
      const r = await req('GET', `/api/chat/${documentId}/history`, { token: accessToken });
      rec('GET /api/chat/:id/history', r.status, r.status === 200, snippet(r.body));
    }
  }

  // ---------- 8. Deadlines ----------
  {
    const r = await req('GET', '/api/deadlines', { token: accessToken });
    rec('GET /api/deadlines', r.status, r.status === 200, snippet(r.body));
  }
  {
    const r = await req('GET', '/api/deadlines/upcoming', { token: accessToken });
    rec('GET /api/deadlines/upcoming', r.status, r.status === 200, snippet(r.body));
  }
  if (documentId) {
    const r = await req('GET', `/api/deadlines/document/${documentId}`, { token: accessToken });
    rec('GET /api/deadlines/document/:id', r.status, r.status === 200, snippet(r.body));
  }
  {
    const body = documentId ? { documentId } : { deadlineIds: [] };
    const r = await req('POST', '/api/deadlines/export/ics', { token: accessToken, body });
    // 200 = exported; 404 = no deadlines for that document yet (expected without AI analysis)
    rec('POST /api/deadlines/export/ics', r.status, r.status === 200 || r.status === 404, snippet(r.text).slice(0, 80));
  }

  // ---------- 9. Notifications ----------
  {
    const r = await req('GET', '/api/notifications', { token: accessToken });
    rec('GET /api/notifications', r.status, r.status === 200, snippet(r.body));
  }
  {
    const r = await req('PUT', '/api/notifications/read-all', { token: accessToken, body: {} });
    rec('PUT /api/notifications/read-all', r.status, r.status === 200, snippet(r.body));
  }

  // ---------- 10. Jurisdictions & languages ----------
  {
    const r = await req('GET', '/api/jurisdictions/countries');
    rec('GET /api/jurisdictions/countries', r.status, r.status === 200, snippet(r.body));
  }
  {
    const r = await req('GET', '/api/jurisdictions/US/states');
    rec('GET /api/jurisdictions/US/states', r.status, r.status === 200 || r.status === 404, snippet(r.body));
  }
  {
    const r = await req('GET', '/api/languages/supported');
    rec('GET /api/languages/supported', r.status, r.status === 200, snippet(r.body));
  }

  // ---------- 11. Features ----------
  if (documentId) {
    {
      const r = await req('PUT', `/api/documents/${documentId}/favorite`, { token: accessToken, body: {} });
      rec('PUT /api/documents/:id/favorite', r.status, r.status === 200, snippet(r.body));
    }
    let shareToken = null;
    {
      const r = await req('POST', `/api/documents/${documentId}/share`, { token: accessToken, body: { expiresInDays: 7 } });
      const ok = r.status === 200 || r.status === 201;
      rec('POST /api/documents/:id/share', r.status, ok, snippet(r.body));
      shareToken = r.body?.data?.token || r.body?.data?.shareToken;
    }
    if (shareToken) {
      const r = await req('GET', `/api/shared/${shareToken}`);
      rec('GET /api/shared/:token', r.status, r.status === 200 || r.status === 404, snippet(r.body));
    }
    {
      const r = await req('GET', `/api/documents/${documentId}/notes`, { token: accessToken });
      rec('GET /api/documents/:id/notes', r.status, r.status === 200, snippet(r.body));
    }
    {
      const r = await req('GET', '/api/playbook/rules', { token: accessToken });
      rec('GET /api/playbook/rules', r.status, r.status === 200, snippet(r.body));
    }
    {
      const r = await req('POST', '/api/playbook/rules', { token: accessToken, body: { name: 'E2E rule', pattern: 'liability', severity: 'high' } });
      rec('POST /api/playbook/rules', r.status, r.status < 500, snippet(r.body));
    }
    {
      const r = await req('GET', `/api/documents/${documentId}/collaborators`, { token: accessToken });
      rec('GET /api/documents/:id/collaborators', r.status, r.status === 200, snippet(r.body));
    }
  }

  // ---------- 12. v1 public analyze (API key) ----------
  if (apiKey) {
    const r = await req('POST', '/api/v1/analyze', {
      token: apiKey,
      body: { sourceType: 'text', content: 'This consulting agreement requires payment of $50,000 within 30 days and may be terminated with 60 days notice under California law.', jurisdiction: 'US-CA', language: 'en' },
    });
    rec('POST /api/v1/analyze (api key)', r.status, r.status < 500, snippet(r.body));
    const docId = r.body?.data?.documentId || r.body?.documentId;
    if (docId) {
      await sleep(2000);
      const g = await req('GET', `/api/v1/analyze/${docId}`, { token: apiKey });
      rec('GET /api/v1/analyze/:id (api key)', g.status, g.status < 500, snippet(g.body));
    }
  } else {
    rec('POST /api/v1/analyze (api key)', '-', 'warn', 'no api key returned from create; skipped');
  }

  // ---------- 13. Document export + delete ----------
  if (documentId) {
    {
      const r = await req('GET', `/api/documents/${documentId}/export`, { token: accessToken });
      rec('GET /api/documents/:id/export', r.status, r.status < 500, snippet(r.text).slice(0, 80));
    }
    {
      const r = await req('DELETE', `/api/documents/${documentId}`, { token: accessToken });
      rec('DELETE /api/documents/:id', r.status, r.status === 200 || r.status === 204, snippet(r.body));
    }
  }

  // ---------- 14. Logout ----------
  {
    const r = await req('POST', '/api/auth/logout', { token: accessToken, body: { refreshToken } });
    rec('POST /api/auth/logout', r.status, r.status === 200, snippet(r.body));
  }

  // ---------- Summary ----------
  console.log(`\n=== SUMMARY ===`);
  console.log(`PASS: ${pass}  WARN: ${warn}  FAIL: ${fail}  TOTAL: ${results.length}`);
  const failures = results.filter((r) => r.ok === false);
  if (failures.length) {
    console.log('\nFAILURES:');
    for (const f of failures) console.log(`  - ${f.name} [${f.status}] ${f.detail}`);
  }
  const warnings = results.filter((r) => r.ok === 'warn');
  if (warnings.length) {
    console.log('\nWARNINGS (non-fatal, often missing AI config):');
    for (const w of warnings) console.log(`  - ${w.name} [${w.status}] ${w.detail}`);
  }
  process.exit(fail > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error('FATAL:', e);
  process.exit(2);
});
