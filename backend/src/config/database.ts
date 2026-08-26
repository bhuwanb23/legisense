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

  pool = new Pool({
    connectionString: getConnectionString(),
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
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
