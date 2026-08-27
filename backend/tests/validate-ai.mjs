// Validates AI-powered analysis on the deployed backend with multiple realistic docs.
// Usage: node tests/validate-ai.mjs
const BASE = process.env.E2E_BASE_URL || 'https://legisense-kr6z.onrender.com';

const DOCS = [
  {
    title: 'Residential Lease Agreement',
    typeHint: 'rental_agreement',
    text: `RESIDENTIAL LEASE AGREEMENT

This Residential Lease Agreement ("Agreement") is entered into as of January 15, 2026, by and between Pacific Property Management LLC ("Landlord") and Sarah Mitchell ("Tenant").

1. PREMISES. Landlord leases to Tenant the apartment located at 4821 Maple Avenue, Unit 3B, Portland, Oregon 97205.

2. TERM. The lease term begins on February 1, 2026 and ends on January 31, 2027. Tenant shall vacate the premises by 12:00 PM on the last day unless a renewal is signed.

3. RENT. Tenant shall pay monthly rent of $1,850, due on the 1st day of each month. A late fee of $75 applies if rent is received after the 5th day. Rent must be paid via electronic transfer.

4. SECURITY DEPOSIT. Tenant shall deposit $1,850 as security. The deposit will be returned within 31 days of move-out, less any deductions for damages beyond normal wear and tear, as required by Oregon law.

5. UTILITIES. Tenant is responsible for electricity, gas, internet, and cable. Landlord provides water, sewer, and trash collection.

6. PETS. No pets are permitted without prior written consent. A pet deposit of $500 per pet applies.

7. MAINTENANCE. Tenant must notify Landlord of any needed repairs within 48 hours. Landlord shall complete non-emergency repairs within 14 days of notice.

8. TERMINATION. Either party may terminate this Agreement with 60 days written notice before the end of the term. Early termination by Tenant requires payment of two months' rent as liquidated damages.

9. SUBLETTING. Tenant shall not sublet or assign this Agreement without Landlord's written consent.

10. GOVERNING LAW. This Agreement is governed by the laws of the State of Oregon.

Signed: Pacific Property Management LLC, Sarah Mitchell`,
  },
  {
    title: 'Mutual Non-Disclosure Agreement',
    typeHint: 'nda',
    text: `MUTUAL NON-DISCLOSURE AGREEMENT

This Mutual Non-Disclosure Agreement ("NDA") is made effective March 3, 2026, between TechNova Solutions Inc. ("Company") and BrightPath Consulting LLC ("Consultant").

1. PURPOSE. The parties wish to explore a potential business collaboration involving AI-powered document analysis technology (the "Purpose").

2. CONFIDENTIAL INFORMATION. "Confidential Information" means all non-public information disclosed by either party, including trade secrets, source code, algorithms, customer lists, financial data, and business plans.

3. OBLIGATIONS. The receiving party shall: (a) hold Confidential Information in strict confidence; (b) not disclose it to third parties without written consent; (c) use it solely for the Purpose; (d) protect it with at least the same degree of care used for its own confidential information, but no less than reasonable care.

4. EXCLUSIONS. Confidential Information does not include information that: (a) is or becomes publicly available through no fault of the receiving party; (b) was known prior to disclosure; (c) is independently developed; (d) is rightfully received from a third party.

5. TERM. This NDA remains in effect for three (3) years from the effective date. Confidentiality obligations survive termination for five (5) years.

6. RETURN OF MATERIALS. Upon written request, each party shall return or destroy all Confidential Information within ten (10) business days.

7. NO LICENSE. Nothing in this NDA grants any license or ownership rights.

8. REMEDIES. Breach may cause irreparable harm. The disclosing party is entitled to injunctive relief without posting bond.

9. GOVERNING LAW. Governed by Delaware law. Disputes resolved by binding arbitration in Wilmington, Delaware.

Signed: TechNova Solutions Inc., BrightPath Consulting LLC`,
  },
  {
    title: 'Employment Agreement - Software Engineer',
    typeHint: 'employment_agreement',
    text: `EMPLOYMENT AGREEMENT

This Employment Agreement is entered into on April 10, 2026, between Meridian Software Corp. ("Employer") and David Chen ("Employee").

1. POSITION. Employee is hired as Senior Software Engineer, reporting to the VP of Engineering. Duties include designing, developing, and maintaining cloud infrastructure software.

2. COMPENSATION. Annual base salary of $165,000, paid bi-weekly. Employee is eligible for an annual performance bonus of up to 15% of base salary.

3. BENEFITS. Employee receives health insurance, 401(k) with 4% employer match, 20 days paid vacation, and 10 sick days per year.

4. WORK LOCATION. Hybrid: three days per week at the San Francisco office, two days remote.

5. PROBATIONARY PERIOD. The first 90 days constitute a probationary period during which either party may terminate with one week's notice.

6. TERMINATION. After probation, either party may terminate with 30 days written notice. Employer may terminate immediately for cause, including material breach, fraud, or gross misconduct.

7. SEVERANCE. If terminated without cause, Employee receives 8 weeks base salary as severance, conditioned on signing a release of claims.

8. CONFIDENTIALITY. Employee shall not disclose Employer's proprietary information during or after employment.

9. INTELLECTUAL PROPERTY. All work product created within the scope of employment belongs to Employer. Employee hereby assigns all such rights.

10. NON-SOLICITATION. For 12 months after termination, Employee shall not solicit Employer's employees or clients.

11. GOVERNING LAW. This Agreement is governed by California law.

Signed: Meridian Software Corp., David Chen`,
  },
];

async function req(method, path, { token, apiKey, body, form } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (apiKey) headers['x-api-key'] = apiKey;
  let payload;
  if (form) { payload = form; }
  else if (body !== undefined) { headers['Content-Type'] = 'application/json'; payload = JSON.stringify(body); }
  const res = await fetch(BASE + path, { method, headers, body: payload });
  const ct = res.headers.get('content-type') || '';
  const text = await res.text();
  let parsed = null;
  try { parsed = ct.includes('json') ? JSON.parse(text) : text; } catch { parsed = text; }
  return { status: res.status, body: parsed };
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const results = [];
function rec(name, ok, detail) {
  results.push({ name, ok, detail });
  console.log(`[${ok ? 'PASS' : 'FAIL'}] ${name}${detail ? ' | ' + detail : ''}`);
}

async function main() {
  console.log(`\n=== AI validation against ${BASE} ===\n`);

  // Register
  const suffix = Math.random().toString(36).slice(2, 9);
  const email = `ai-val-${suffix}@test.com`;
  const reg = await req('POST', '/api/auth/register', { body: { fullName: 'AI Validator', email, password: 'Str0ng!Pass#2026' } });
  if (reg.status !== 201) { console.error('Register failed:', JSON.stringify(reg.body)); process.exit(1); }
  const token = reg.body.data.accessToken;
  console.log(`Registered ${email}\n`);

  const docIds = [];
  for (const doc of DOCS) {
    const up = await req('POST', '/api/documents/upload', {
      token,
      form: (() => {
        const fd = new FormData();
        fd.append('source_type', 'paste');
        fd.append('text', doc.text);
        fd.append('title', doc.title);
        fd.append('type_hint', doc.typeHint);
        return fd;
      })(),
    });
    const id = up.body?.data?.documentId;
    rec(`upload "${doc.title}"`, up.status === 202 && id, `status=${up.status} id=${id}`);
    if (id) docIds.push({ id, title: doc.title, typeHint: doc.typeHint });
  }

  // Start analysis for all
  for (const d of docIds) {
    const r = await req('POST', `/api/analysis/start/${d.id}`, { token, body: {} });
    rec(`start analysis "${d.title}"`, r.status === 202, `status=${r.status}`);
  }

  // Poll until all analyzed (max 4 min)
  console.log('\nWaiting for analysis to complete (up to 4 min)...');
  const deadline = Date.now() + 240_000;
  const done = new Set();
  while (done.size < docIds.length && Date.now() < deadline) {
    await sleep(5000);
    for (const d of docIds) {
      if (done.has(d.id)) continue;
      const r = await req('GET', `/api/analysis/${d.id}`, { token });
      const status = r.body?.data?.status;
      if (status === 'analyzed' || status === 'failed') done.add(d.id);
    }
    process.stdout.write(`  analyzed: ${done.size}/${docIds.length}\r`);
  }
  console.log('');

  // Validate each analysis
  let aiUsed = 0;
  for (const d of docIds) {
    const r = await req('GET', `/api/analysis/${d.id}`, { token });
    const a = r.body?.data?.analysis;
    const status = r.body?.data?.status;
    if (!a) { rec(`analysis "${d.title}"`, false, `status=${status}, no analysis object`); continue; }

    const model = a.aiModelUsed || a.ai_model_used || 'unknown';
    const isHeuristic = /heuristic/i.test(String(model));
    if (!isHeuristic) aiUsed++;

    const clausesR = await req('GET', `/api/analysis/${d.id}/clauses`, { token });
    const clauseCount = clausesR.body?.data?.clauses?.length ?? 0;

    const risksR = await req('GET', `/api/analysis/${d.id}/risks`, { token });
    const riskItems = risksR.body?.data?.items?.length ?? 0;

    const summaryR = await req('GET', `/api/analysis/${d.id}/summary`, { token });
    const summary = summaryR.body?.data?.summary || '';

    const missingR = await req('GET', `/api/analysis/${d.id}/missing-clauses`, { token });
    const missingCritical = missingR.body?.data?.missing?.critical?.length ?? 0;
    const missingRecommended = missingR.body?.data?.missing?.recommended?.length ?? 0;

    const detectedType = a.documentType || 'unknown';
    const score = a.overallRiskScore ?? a.overall_risk_score ?? 'n/a';

    rec(`analysis "${d.title}"`, status === 'analyzed',
      `model=${model} type="${detectedType}" score=${score} clauses=${clauseCount} risks=${riskItems} missing=${missingCritical}c/${missingRecommended}r`);
    if (summary) console.log(`    summary: ${String(summary).slice(0, 160)}`);
  }

  // Chat quality check on first doc
  if (docIds.length) {
    const d = docIds[0];
    const sess = await req('POST', `/api/chat/${d.id}/session`, { token, body: {} });
    const sessionId = sess.body?.data?.sessionId;
    if (sessionId) {
      const msg = await req('POST', `/api/chat/${d.id}/message`, { token, body: { sessionId, message: 'What is the monthly rent and when is it due? What happens if I pay late?' } });
      const content = msg.body?.data?.message?.content || '';
      const mentions1850 = content.includes('1,850') || content.includes('1850');
      const mentionsLate = /late|fee|75/i.test(content);
      rec(`chat Q&A on "${d.title}"`, msg.status === 201 && content.length > 50,
        `len=${content.length} rent_mentioned=${mentions1850} late_fee=${mentionsLate}`);
      console.log(`    answer: ${content.slice(0, 220)}`);
    }
  }

  // Classify check (should use AI now)
  if (docIds.length) {
    const d = docIds[1]; // NDA
    const r = await req('GET', `/api/analysis/${d.id}/classify`, { token });
    const type = r.body?.data?.type;
    const conf = r.body?.data?.confidence;
    const needs = r.body?.data?.needsConfirmation;
    rec(`classify "${d.title}"`, r.status === 200, `type=${type} confidence=${conf} needsConfirmation=${needs}`);
  }

  // Cleanup
  for (const d of docIds) await req('DELETE', `/api/documents/${d.id}`, { token });
  await req('POST', '/api/auth/logout', { token });

  const pass = results.filter((r) => r.ok).length;
  console.log(`\n=== SUMMARY: ${pass}/${results.length} passed, AI provider used in ${aiUsed}/${docIds.length} analyses ===`);
  if (aiUsed === 0) {
    console.log('\nNOTE: All analyses used the heuristic fallback. OpenRouter is likely being skipped.');
    console.log('Check: OPENROUTER_MODEL must be set to a specific model (not "openrouter/free" or "openrouter/auto").');
  }
  process.exit(pass === results.length ? 0 : 1);
}

main().catch((e) => { console.error(e); process.exit(1); });
