import { Pool } from 'pg';
import { drizzle, type NodePgDatabase } from 'drizzle-orm/node-postgres';
import * as schema from '../models';

let pool: Pool | null = null;
let db: NodePgDatabase<typeof schema> | null = null;

function getConnectionString(): string {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error(
      'DATABASE_URL is not set. For Render PostgreSQL, set DATABASE_URL in your environment variables.',
    );
  }
  return url;
}

export async function initDatabase(): Promise<NodePgDatabase<typeof schema>> {
  if (db) return db;

  // Render PostgreSQL requires SSL; local dev databases usually do not use it.
  const needsSsl =
    process.env.DATABASE_SSL === 'true' ||
    (getConnectionString().includes('render.com') && process.env.DATABASE_SSL !== 'false');

  pool = new Pool({
    connectionString: getConnectionString(),
    ssl: needsSsl ? { rejectUnauthorized: false } : undefined,
    // Keep the pool small: Render Postgres has tight connection limits and
    // the queue workers share this pool with the HTTP server.
    max: 5,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
    // Render fronts Postgres with pgbouncer, which drops idle connections.
    // Keep-alive prevents stale sockets that fail on next use.
    keepAlive: true,
    keepAliveInitialDelayMillis: 10000,
  });

  // Prevent idle client errors (e.g. pgbouncer disconnects) from crashing
  // the process; the pool will simply reconnect on next use.
  pool.on('error', (err) => {
    console.error('Unexpected pool error:', err.message);
  });

  // Test the connection
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT NOW()');
    console.log(`Database connected: ${result.rows[0].now}`);
  } finally {
    client.release();
  }

  db = drizzle(pool, { schema });
  return db;
}

export function getPool(): Pool {
  if (!pool) throw new Error('Database not initialized. Call initDatabase() first.');
  return pool;
}

export function getDb(): NodePgDatabase<typeof schema> {
  if (!db) throw new Error('Database not initialized. Call initDatabase() first.');
  return db;
}

/**
 * No-op in PostgreSQL — data is persisted by the managed database.
 * Kept for call-site compatibility.
 */
export function persistNow(): void {
  // PostgreSQL handles persistence automatically.
}

export async function closeDatabase(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
    db = null;
    console.log('Database connection pool closed.');
  }
}
