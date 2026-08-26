/* Poll until the newest deploy is live. Canary: POST /api/users/api-keys must
 * return a real key (the un-awaited Promise bug returned {}). */
const BASE = process.env.E2E_BASE || 'https://legisense-kr6z.onrender.com';
const uniq = Date.now().toString(36);
const EMAIL = `canary-${uniq}@test.com`;
const PASSWORD = 'TestPass1!Complex';

async function req(method, path, { body, token } = {}) {
  const h = {};
  if (token) h['Authorization'] = `Bearer ${token}`;
  let payload;
  if (body !== undefined) { h['Content-Type'] = 'application/json'; payload = JSON.stringify(body); }
  const res = await fetch(BASE + path, { method, headers: h, body: payload });
  const text = await res.text();
  let json; try { json = JSON.parse(text); } catch { json = text; }
  return { status: res.status, body: json };
}

(async () => {
  const reg = await req('POST', '/api/auth/register', { body: { fullName: 'Canary', email: EMAIL, password: PASSWORD } });
  const token = reg.body?.data?.accessToken;
  if (!token) { console.log('NO_TOKEN', reg.status, JSON.stringify(reg.body).slice(0, 200)); process.exit(2); }

  for (let i = 1; i <= 40; i++) {
    const r = await req('POST', '/api/users/api-keys', { token, body: { name: 'canary' } });
    const key = r.body?.data?.key;
    if (key) {
      console.log(`DEPLOY_LIVE after ${i} probes. api key prefix: ${String(key).slice(0, 12)}...`);
      process.exit(0);
    }
    console.log(`probe ${i}: not live yet (data=${JSON.stringify(r.body?.data)})`);
    await new Promise((r) => setTimeout(r, 20000));
  }
  console.log('TIMEOUT: deploy not live after ~13min');
  process.exit(1);
})();
