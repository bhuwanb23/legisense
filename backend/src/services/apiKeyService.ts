import crypto from 'crypto';
import { getDb, persistNow } from '../config/database';
import { apiKeys, users } from '../models';
import { sql } from 'drizzle-orm';
import { BadRequestError, NotFoundError, UnauthorizedError } from '../utils/errors';

const DAILY_LIMIT = 100;

function hashKey(raw: string): string {
  return crypto.createHash('sha256').update(raw).digest('hex');
}

export function createApiKey(userId: number, name = 'default'): { id: number; name: string; key: string; keyPrefix: string } {
  const raw = `ls_${crypto.randomBytes(24).toString('hex')}`;
  const keyHash = hashKey(raw);
  const keyPrefix = raw.slice(0, 10);
  const db = getDb();
  db.insert(apiKeys).values({
    userId,
    name,
    keyPrefix,
    keyHash,
    isActive: true,
    dailyCount: 0,
    dailyReset: new Date().toISOString().slice(0, 10),
  }).run();
  persistNow();
  const row = db.select().from(apiKeys).where(sql`${apiKeys.keyHash} = ${keyHash}`).all()[0];
  return { id: row.id, name: row.name, key: raw, keyPrefix };
}

export function listApiKeys(userId: number) {
  const db = getDb();
  return db.select().from(apiKeys).where(sql`${apiKeys.userId} = ${userId}`).all()
    .map((k) => ({
      id: k.id,
      name: k.name,
      keyPrefix: k.keyPrefix,
      isActive: k.isActive,
      lastUsedAt: k.lastUsedAt,
      createdAt: k.createdAt,
    }));
}

export function revokeApiKey(userId: number, id: number): void {
  const db = getDb();
  const row = db.select().from(apiKeys).where(sql`${apiKeys.id} = ${id} AND ${apiKeys.userId} = ${userId}`).all()[0];
  if (!row) throw new NotFoundError('API key');
  db.run(sql`UPDATE ${apiKeys} SET is_active = 0 WHERE id = ${id}`);
  persistNow();
}

export function authenticateApiKey(
  raw: string,
  opts: { countUsage?: boolean } = { countUsage: true },
): { id: number; email: string; fullName: string | null; authProvider: string | null; isActive: boolean } {
  if (!raw.startsWith('ls_')) {
    throw new UnauthorizedError('Invalid API key');
  }
  const db = getDb();
  const keyHash = hashKey(raw);
  const key = db.select().from(apiKeys).where(sql`${apiKeys.keyHash} = ${keyHash}`).all()[0];
  if (!key || !key.isActive) throw new UnauthorizedError('Invalid API key');
  const today = new Date().toISOString().slice(0, 10);
  let count = key.dailyCount || 0;
  if (key.dailyReset !== today) {
    count = 0;
    db.run(sql`UPDATE ${apiKeys} SET daily_count = 0, daily_reset = ${today} WHERE id = ${key.id}`);
  }
  if (opts.countUsage !== false) {
    if (count >= DAILY_LIMIT) {
      throw new BadRequestError('API key daily limit reached (100/day)');
    }
    db.run(sql`UPDATE ${apiKeys} SET daily_count = ${count + 1}, last_used_at = datetime('now') WHERE id = ${key.id}`);
    persistNow();
  }
  const user = db.select().from(users).where(sql`${users.id} = ${key.userId}`).all()[0];
  if (!user || !user.isActive) throw new UnauthorizedError('User not found');
  return { id: user.id, email: user.email, fullName: user.fullName, authProvider: user.authProvider, isActive: user.isActive };
}
