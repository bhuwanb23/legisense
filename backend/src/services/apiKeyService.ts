import crypto from 'crypto';
import { getDb, persistNow } from '../config/database';
import { apiKeys, users } from '../models';
import { sql } from 'drizzle-orm';
import { BadRequestError, NotFoundError, UnauthorizedError } from '../utils/errors';

const DAILY_LIMIT = 100;

function hashKey(raw: string): string {
  return crypto.createHash('sha256').update(raw).digest('hex');
}

export async function createApiKey(userId: number, name = 'default'): Promise<{ id: number; name: string; key: string; keyPrefix: string }> {
  const raw = `ls_${crypto.randomBytes(24).toString('hex')}`;
  const keyHash = hashKey(raw);
  const keyPrefix = raw.slice(0, 10);
  const db = getDb();
  await db.insert(apiKeys).values({
    userId,
    name,
    keyPrefix,
    keyHash,
    isActive: true,
    dailyCount: 0,
    dailyReset: new Date().toISOString().slice(0, 10),
  });
  persistNow();
  const row = (await db.select().from(apiKeys).where(sql`${apiKeys.keyHash} = ${keyHash}`))[0];
  return { id: row.id, name: row.name, key: raw, keyPrefix };
}

export async function listApiKeys(userId: number) {
  const db = getDb();
  return (await db.select().from(apiKeys).where(sql`${apiKeys.userId} = ${userId}`))
    .map((k) => ({
      id: k.id,
      name: k.name,
      keyPrefix: k.keyPrefix,
      isActive: k.isActive,
      lastUsedAt: k.lastUsedAt,
      createdAt: k.createdAt,
    }));
}

export async function revokeApiKey(userId: number, id: number): Promise<void> {
  const db = getDb();
  const row = (await db.select().from(apiKeys).where(sql`${apiKeys.id} = ${id} AND ${apiKeys.userId} = ${userId}`))[0];
  if (!row) throw new NotFoundError('API key');
  await db.execute(sql`UPDATE ${apiKeys} SET is_active = FALSE WHERE id = ${id}`);
  persistNow();
}

export async function authenticateApiKey(
  raw: string,
  opts: { countUsage?: boolean } = { countUsage: true },
): Promise<{ id: number; email: string; fullName: string | null; authProvider: string | null; isActive: boolean }> {
  if (!raw.startsWith('ls_')) {
    throw new UnauthorizedError('Invalid API key');
  }
  const db = getDb();
  const keyHash = hashKey(raw);
  const key = (await db.select().from(apiKeys).where(sql`${apiKeys.keyHash} = ${keyHash}`))[0];
  if (!key || !key.isActive) throw new UnauthorizedError('Invalid API key');
  const today = new Date().toISOString().slice(0, 10);
  let count = key.dailyCount || 0;
  if (key.dailyReset !== today) {
    count = 0;
    await db.execute(sql`UPDATE ${apiKeys} SET daily_count = 0, daily_reset = ${today} WHERE id = ${key.id}`);
  }
  if (opts.countUsage !== false) {
    if (count >= DAILY_LIMIT) {
      throw new BadRequestError('API key daily limit reached (100/day)');
    }
    await db.execute(sql`UPDATE ${apiKeys} SET daily_count = ${count + 1}, last_used_at = NOW() WHERE id = ${key.id}`);
    persistNow();
  }
  const user = (await db.select().from(users).where(sql`${users.id} = ${key.userId}`))[0];
  if (!user || !user.isActive) throw new UnauthorizedError('User not found');
  return { id: user.id, email: user.email, fullName: user.fullName, authProvider: user.authProvider, isActive: user.isActive };
}
