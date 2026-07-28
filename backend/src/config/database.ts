import initSqlJs, { type Database } from 'sql.js';
import { drizzle, type SQLJsDatabase } from 'drizzle-orm/sql-js';
import path from 'path';
import fs from 'fs';

const DB_DIR = path.resolve(__dirname, '../../data');
const DB_PATH = path.join(DB_DIR, 'legisense.db');

let sqlClient: Database | null = null;
let db: SQLJsDatabase | null = null;

export async function initDatabase(): Promise<SQLJsDatabase> {
  if (db) return db;

  if (!fs.existsSync(DB_DIR)) {
    fs.mkdirSync(DB_DIR, { recursive: true });
  }

  const SQL = await initSqlJs();

  if (fs.existsSync(DB_PATH)) {
    const buffer = fs.readFileSync(DB_PATH);
    sqlClient = new SQL.Database(buffer);
  } else {
    sqlClient = new SQL.Database();
  }

  sqlClient.run('PRAGMA foreign_keys = ON');

  db = drizzle(sqlClient);

  persistDatabase();

  console.log(`Database connected: ${DB_PATH}`);
  return db;
}

function persistDatabase(): void {
  if (!sqlClient) return;

  const data = sqlClient.export();
  const buffer = Buffer.from(data);
  fs.writeFileSync(DB_PATH, buffer);
}

export function getDb(): SQLJsDatabase {
  if (!db) throw new Error('Database not initialized. Call initDatabase() first.');
  return db;
}

export function persistNow(): void {
  persistDatabase();
}

export function closeDatabase(): void {
  if (sqlClient) {
    persistDatabase();
    sqlClient.close();
    sqlClient = null;
    db = null;
    console.log('Database closed.');
  }
}
