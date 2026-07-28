import { Request, Response, NextFunction } from 'express';
import bcrypt from 'bcrypt';

import { initDatabase, getDb, closeDatabase, persistNow } from '../src/config/database';
import { sql } from 'drizzle-orm';
import { users, sessions } from '../src/models';

import {
  generateToken,
  generateRefreshToken,
  verifyToken,
} from '../src/middleware/auth';

const results: { test: string; pass: boolean; detail?: string }[] = [];

function assert(condition: boolean, test: string, detail?: string) {
  results.push({ test, pass: condition, detail });
  console.log(`  ${condition ? '✅' : '❌'} ${test}${detail ? ` — ${detail}` : ''}`);
}

function mockReq(overrides?: Partial<Request>): Request {
  return {
    headers: {},
    body: {},
    method: 'POST',
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

function authedReq(userId: number, email: string, body: unknown = {}): Request {
  return mockReq({
    body,
    user: { id: userId, email, fullName: 'Test User', authProvider: 'email', isActive: true },
  });
}

async function run() {
  console.log('🧪 Auth + User Tests\n');

  await initDatabase();
  const db = getDb();

  // Clean slate
  db.run(sql`DELETE FROM ${sessions}`);
  db.run(sql`DELETE FROM ${users}`);
  persistNow();

  // ═══════════════════════════════════════════════════
  //  1. AUTH SCHEMAS
  // ═══════════════════════════════════════════════════
  console.log('── 1. Auth Schemas ──');

  const { registerSchema, loginSchema, refreshTokenSchema } = await import('../src/schemas/authSchemas');

  const validReg = registerSchema.safeParse({
    fullName: 'Test User',
    email: 'test@example.com',
    password: 'password123',
  });
  assert(validReg.success, 'registerSchema accepts valid input');

  const badEmail = registerSchema.safeParse({
    fullName: 'Test',
    email: 'not-an-email',
    password: 'password123',
  });
  assert(!badEmail.success, 'registerSchema rejects invalid email');

  const shortPass = registerSchema.safeParse({
    fullName: 'Test',
    email: 'test@example.com',
    password: '123',
  });
  assert(!shortPass.success, 'registerSchema rejects short password');

  const validLogin = loginSchema.safeParse({
    email: 'test@example.com',
    password: 'password123',
  });
  assert(validLogin.success, 'loginSchema accepts valid input');

  const noEmail = loginSchema.safeParse({ password: 'password123' });
  assert(!noEmail.success, 'loginSchema requires email');

  const validRefresh = refreshTokenSchema.safeParse({
    refreshToken: 'some-token',
  });
  assert(validRefresh.success, 'refreshTokenSchema accepts valid input');

  // ═══════════════════════════════════════════════════
  //  2. PASSWORD HASHING
  // ═══════════════════════════════════════════════════
  console.log('\n── 2. Password Hashing ──');

  const password = 'my-secure-password';
  const hash = await bcrypt.hash(password, 12);
  assert(hash !== password, 'Hash is different from plaintext');
  assert(hash.startsWith('$2b$'), 'Hash uses bcrypt format');

  const match = await bcrypt.compare(password, hash);
  assert(match === true, 'bcrypt.compare matches correct password');

  const noMatch = await bcrypt.compare('wrong-password', hash);
  assert(noMatch === false, 'bcrypt.compare rejects wrong password');

  // ═══════════════════════════════════════════════════
  //  3. JWT TOKENS
  // ═══════════════════════════════════════════════════
  console.log('\n── 3. JWT Tokens ──');

  const payload = { userId: 1, email: 'test@example.com' };
  const token = generateToken(payload);
  assert(typeof token === 'string', 'generateToken returns string');
  assert(token.split('.').length === 3, 'Token has 3 JWT parts');

  const decoded = verifyToken(token);
  assert(decoded.userId === 1, 'verifyToken decodes userId');
  assert(decoded.email === 'test@example.com', 'verifyToken decodes email');

  const refresh = generateRefreshToken(payload);
  assert(typeof refresh === 'string', 'generateRefreshToken returns string');
  assert(refresh.split('.').length === 3, 'Refresh token has 3 JWT parts');

  // Two tokens should be different (random jti)
  const refresh2 = generateRefreshToken(payload);
  assert(refresh !== refresh2, 'Two refresh tokens are unique');

  let invalidTokenThrew = false;
  try { verifyToken('invalid-token'); } catch { invalidTokenThrew = true; }
  assert(invalidTokenThrew, 'verifyToken throws on invalid token');

  // ═══════════════════════════════════════════════════
  //  4. REGISTER CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 4. Register Controller ──');

  const { register } = await import('../src/controllers/authController');

  const regRes = mockRes();
  await register(
    mockReq({
      body: { fullName: 'John Doe', email: 'john@test.com', password: 'securepass123' },
      headers: { 'user-agent': 'test-agent' },
      ip: '127.0.0.1',
    }),
    regRes,
    mockNext()
  );

  assert(regRes.statusCode === 201, 'Register returns 201');
  const regBody = regRes.body as Record<string, unknown>;
  assert(regBody.success === true, 'Register returns success');
  const regData = regBody.data as Record<string, unknown>;
  assert(typeof regData.accessToken === 'string', 'Register returns accessToken');
  assert(typeof regData.refreshToken === 'string', 'Register returns refreshToken');

  // Get actual user ID from DB
  const userRows = db.select().from(users).where(sql`${users.email} = 'john@test.com'`).all();
  assert(userRows.length === 1, 'User created in DB');
  assert(userRows[0].passwordHash !== 'securepass123', 'Password is hashed in DB');
  assert(userRows[0].fullName === 'John Doe', 'Full name stored correctly');

  const userId = userRows[0].id;
  console.log(`  ℹ️  User ID: ${userId}`);

  // Check session
  const sessionRows = db.select().from(sessions).where(sql`${sessions.userId} = ${userId}`).all();
  assert(sessionRows.length >= 1, 'Session created for new user');

  // Duplicate email
  let conflictThrew = false;
  try {
    await register(
      mockReq({ body: { fullName: 'Duplicate', email: 'john@test.com', password: 'pass12345' } }),
      mockRes(),
      mockNext()
    );
  } catch (e: unknown) {
    conflictThrew = (e as { statusCode?: number }).statusCode === 409;
  }
  assert(conflictThrew, 'Register throws 409 for duplicate email');

  // ═══════════════════════════════════════════════════
  //  5. LOGIN CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 5. Login Controller ──');

  const { login } = await import('../src/controllers/authController');

  const loginRes = mockRes();
  await login(
    mockReq({ body: { email: 'john@test.com', password: 'securepass123' } }),
    loginRes,
    mockNext()
  );

  assert(loginRes.statusCode === 200, 'Login returns 200');
  const loginBody = loginRes.body as Record<string, unknown>;
  assert(loginBody.success === true, 'Login returns success');
  const loginData = loginBody.data as Record<string, unknown>;
  assert(typeof loginData.accessToken === 'string', 'Login returns accessToken');
  assert(typeof loginData.refreshToken === 'string', 'Login returns refreshToken');

  // Wrong password
  let unauthorizedThrew = false;
  try {
    await login(
      mockReq({ body: { email: 'john@test.com', password: 'wrong' } }),
      mockRes(),
      mockNext()
    );
  } catch (e: unknown) {
    unauthorizedThrew = (e as { statusCode?: number }).statusCode === 401;
  }
  assert(unauthorizedThrew, 'Login throws 401 for wrong password');

  // Nonexistent email
  let notFoundThrew = false;
  try {
    await login(
      mockReq({ body: { email: 'nobody@test.com', password: 'pass' } }),
      mockRes(),
      mockNext()
    );
  } catch (e: unknown) {
    notFoundThrew = (e as { statusCode?: number }).statusCode === 401;
  }
  assert(notFoundThrew, 'Login throws 401 for nonexistent email');

  // ═══════════════════════════════════════════════════
  //  6. LOGOUT CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 6. Logout Controller ──');

  const { logout } = await import('../src/controllers/authController');

  // Get a valid refresh token from a fresh login
  const loginRes2 = mockRes();
  await login(
    mockReq({ body: { email: 'john@test.com', password: 'securepass123' } }),
    loginRes2,
    mockNext()
  );
  const loginData2 = (loginRes2.body as Record<string, unknown>).data as Record<string, unknown>;
  const refreshTok = loginData2.refreshToken as string;

  const logoutRes = mockRes();
  await logout(
    authedReq(userId, 'john@test.com', { refreshToken: refreshTok }),
    logoutRes,
    mockNext()
  );

  assert(logoutRes.statusCode === 200, 'Logout returns 200');
  const logoutBody = logoutRes.body as Record<string, unknown>;
  assert(logoutBody.success === true, 'Logout returns success');

  // Verify session revoked via raw SQL to be sure
  const revokedCheck = db.all(
    sql`SELECT is_revoked FROM sessions WHERE refresh_token = ${refreshTok}`
  ) as Array<{ is_revoked: number }>;
  assert(revokedCheck.length > 0, 'Session found in DB');
  assert(revokedCheck[0].is_revoked === 1, 'Session is_revoked = 1 in DB');

  // Logout all sessions
  const logoutAllRes = mockRes();
  await logout(authedReq(userId, 'john@test.com', {}), logoutAllRes, mockNext());
  assert(logoutAllRes.statusCode === 200, 'Logout all returns 200');

  const allRevoked = db.all(
    sql`SELECT is_revoked FROM sessions WHERE user_id = ${userId} AND is_revoked = 0`
  ) as Array<unknown>;
  assert(allRevoked.length === 0, 'All sessions revoked');

  // ═══════════════════════════════════════════════════
  //  7. REFRESH TOKEN CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 7. Refresh Token Controller ──');

  const { refreshToken: refreshCtrl } = await import('../src/controllers/authController');

  // Login to get a fresh (unrevoked) refresh token
  const loginRes3 = mockRes();
  await login(
    mockReq({ body: { email: 'john@test.com', password: 'securepass123' } }),
    loginRes3,
    mockNext()
  );
  const loginData3 = (loginRes3.body as Record<string, unknown>).data as Record<string, unknown>;
  const freshRefresh = loginData3.refreshToken as string;

  const refreshRes = mockRes();
  await refreshCtrl(
    mockReq({ body: { refreshToken: freshRefresh } }),
    refreshRes,
    mockNext()
  );

  assert(refreshRes.statusCode === 200, 'Refresh returns 200');
  const refreshBody = refreshRes.body as Record<string, unknown>;
  assert(refreshBody.success === true, 'Refresh returns success');
  const refreshData = refreshBody.data as Record<string, unknown>;
  assert(typeof refreshData.accessToken === 'string', 'Refresh returns new accessToken');
  assert(typeof refreshData.refreshToken === 'string', 'Refresh returns new refreshToken');
  assert(refreshData.refreshToken !== freshRefresh, 'New refresh token is different');

  // Old refresh token should be revoked
  const oldSessionCheck = db.all(
    sql`SELECT is_revoked FROM sessions WHERE refresh_token = ${freshRefresh}`
  ) as Array<{ is_revoked: number }>;
  assert(oldSessionCheck.length > 0, 'Old session exists');
  assert(oldSessionCheck[0].is_revoked === 1, 'Old session is revoked');

  // Invalid refresh token
  let invalidRefreshThrew = false;
  try {
    await refreshCtrl(
      mockReq({ body: { refreshToken: 'totally-invalid-token' } }),
      mockRes(),
      mockNext()
    );
  } catch (e: unknown) {
    invalidRefreshThrew = (e as { statusCode?: number }).statusCode === 401;
  }
  assert(invalidRefreshThrew, 'Refresh throws 401 for invalid token');

  // ═══════════════════════════════════════════════════
  //  8. FORGOT PASSWORD CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 8. Forgot Password Controller ──');

  const { forgotPassword } = await import('../src/controllers/authController');

  const forgotRes = mockRes();
  await forgotPassword(
    mockReq({ body: { email: 'john@test.com' } }),
    forgotRes,
    mockNext()
  );

  assert(forgotRes.statusCode === 200, 'Forgot password returns 200');
  const forgotBody = forgotRes.body as Record<string, unknown>;
  assert(forgotBody.success === true, 'Forgot password returns success');
  const forgotData = forgotBody.data as Record<string, unknown>;
  assert(typeof forgotData.resetToken === 'string', 'Forgot password returns resetToken in dev mode');

  // Non-existent email still returns success (prevent enumeration)
  const forgotRes2 = mockRes();
  await forgotPassword(
    mockReq({ body: { email: 'nobody@test.com' } }),
    forgotRes2,
    mockNext()
  );
  const forgotBody2 = forgotRes2.body as Record<string, unknown>;
  assert(forgotBody2.success === true, 'Forgot password returns success for non-existent email');

  // ═══════════════════════════════════════════════════
  //  9. RESET PASSWORD CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 9. Reset Password Controller ──');

  const { resetPassword } = await import('../src/controllers/authController');

  const resetToken = forgotData.resetToken as string;

  const resetRes = mockRes();
  await resetPassword(
    mockReq({ body: { token: resetToken, newPassword: 'newpassword123' } }),
    resetRes,
    mockNext()
  );

  assert(resetRes.statusCode === 200, 'Reset password returns 200');
  const resetBody = resetRes.body as Record<string, unknown>;
  assert(resetBody.success === true, 'Reset password returns success');

  // Verify old password no longer works
  let oldPassFails = false;
  try {
    await login(
      mockReq({ body: { email: 'john@test.com', password: 'securepass123' } }),
      mockRes(),
      mockNext()
    );
  } catch (e: unknown) {
    oldPassFails = (e as { statusCode?: number }).statusCode === 401;
  }
  assert(oldPassFails, 'Old password no longer works after reset');

  // New password works
  const newLoginRes = mockRes();
  await login(
    mockReq({ body: { email: 'john@test.com', password: 'newpassword123' } }),
    newLoginRes,
    mockNext()
  );
  assert(newLoginRes.statusCode === 200, 'New password works after reset');

  // All sessions revoked after reset — verify old tokens are revoked
  // Count sessions created before reset (from earlier test steps 5-7)
  const totalSessions = db.all(
    sql`SELECT id, is_revoked FROM sessions WHERE user_id = ${userId}`
  ) as Array<{ id: number; is_revoked: number }>;
  const unrevoked = totalSessions.filter((s) => s.is_revoked === 0);
  // Only the new login session (created above) should be unrevoked
  assert(unrevoked.length <= 1, 'At most 1 unrevoked session (the fresh login)');
  assert(totalSessions.length >= 2, 'Multiple sessions exist (old + new)');

  // ═══════════════════════════════════════════════════
  //  10. USER PROFILE CONTROLLER
  // ═══════════════════════════════════════════════════
  console.log('\n── 10. User Profile Controller ──');

  const { getProfile, updateProfile, updatePreferences, deleteAccount } = await import('../src/controllers/userController');

  // Get profile
  const profileRes = mockRes();
  await getProfile(authedReq(userId, 'john@test.com'), profileRes, mockNext());
  assert(profileRes.statusCode === 200, 'Get profile returns 200');
  const profileBody = profileRes.body as Record<string, unknown>;
  const profileData = profileBody.data as Record<string, unknown>;
  assert(profileData.email === 'john@test.com', 'Profile has correct email');
  assert(profileData.fullName === 'John Doe', 'Profile has correct fullName');

  // Update profile
  const updateRes = mockRes();
  await updateProfile(
    authedReq(userId, 'john@test.com', { fullName: 'John Updated', profession: 'Lawyer' }),
    updateRes,
    mockNext()
  );
  assert(updateRes.statusCode === 200, 'Update profile returns 200');
  const updateBody = updateRes.body as Record<string, unknown>;
  const updateData = updateBody.data as Record<string, unknown>;
  assert(updateData.fullName === 'John Updated', 'Profile name updated');
  assert(updateData.profession === 'Lawyer', 'Profile profession updated');

  // Update preferences
  const prefRes = mockRes();
  await updatePreferences(
    authedReq(userId, 'john@test.com', { preferredLanguage: 'es', defaultJurisdiction: 'India' }),
    prefRes,
    mockNext()
  );
  assert(prefRes.statusCode === 200, 'Update preferences returns 200');
  const prefBody = prefRes.body as Record<string, unknown>;
  const prefData = prefBody.data as Record<string, unknown>;
  assert(prefData.preferredLanguage === 'es', 'Language preference updated');

  // Delete account (soft delete)
  const delRes = mockRes();
  await deleteAccount(authedReq(userId, 'john@test.com'), delRes, mockNext());
  assert(delRes.statusCode === 200, 'Delete account returns 200');

  // Verify deactivated
  const deletedUser = db.all(
    sql`SELECT is_active FROM users WHERE id = ${userId}`
  ) as Array<{ is_active: number }>;
  assert(deletedUser[0].is_active === 0, 'Account is deactivated');

  // Verify sessions revoked
  const revokedSessionsAfterDelete = db.all(
    sql`SELECT is_revoked FROM sessions WHERE user_id = ${userId} AND is_revoked = 0`
  ) as Array<unknown>;
  assert(revokedSessionsAfterDelete.length === 0, 'All sessions revoked on account deletion');

  // Login fails for deactivated account
  let deactivatedFails = false;
  try {
    await login(
      mockReq({ body: { email: 'john@test.com', password: 'newpassword123' } }),
      mockRes(),
      mockNext()
    );
  } catch (e: unknown) {
    deactivatedFails = (e as { statusCode?: number }).statusCode === 401;
  }
  assert(deactivatedFails, 'Login fails for deactivated account');

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
