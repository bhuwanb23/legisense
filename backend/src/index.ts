import http from 'http';
import fs from 'fs';
import path from 'path';
import app from './app';
import { initDatabase, getPool, closeDatabase, getDb } from './config/database';
import { sql } from 'drizzle-orm';
import {
  users, documents, analysisResults,
  clauses, riskItems, deadlines, chatMessages,
  notifications, sessions, usageLogs, queueJobs,
  glossary, jurisdictions, legalRules, jurisdictionFlags, jurisdictionConflicts,
  riskPatterns, clauseRiskFlags, communityRiskFeedback, requiredClausesTemplates,
  shareLinks, clauseNotes, playbookRules,
  playbookFlags, apiKeys, documentCollaborators,
} from './models';
import { legalGlossary } from './data/legalGlossary';
import { seedJurisdictionsAndRules } from './data/seedJurisdictions';
import { seedRiskAndRequiredLibraries } from './data/seedRiskLibraries';
import { initSocketIO, closeSocketIO } from './services/socketService';
import { startQueueSystem, stopQueueSystem } from './queue';
import { Pool } from 'pg';

const port = Number(process.env.PORT) || 3001;

async function runSchema(pool: Pool): Promise<void> {
  const schemaPath = path.join(__dirname, 'config', 'schema.sql');
  const schema = fs.readFileSync(schemaPath, 'utf8');
  await pool.query(schema);
  console.log('Schema tables created/verified.');
}

async function start() {
  const db = await initDatabase();

  // Run schema SQL via the shared raw pg pool (Drizzle doesn't have a push API at runtime)
  await runSchema(getPool());

  // Seed legal glossary
  const existingTerms = await db.select({ count: sql<number>`count(*)` }).from(glossary);
  if (Number(existingTerms[0]?.count ?? 0) === 0) {
    let seeded = 0;
    for (const entry of legalGlossary) {
      try {
        await db.insert(glossary).values({ term: entry.term, definition: entry.definition, category: entry.category });
        seeded++;
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        if (!message.includes('unique') && !message.includes('UNIQUE')) throw err;
      }
    }
    console.log(`Seeded ${seeded} legal glossary terms.`);
  }

  await seedJurisdictionsAndRules();
  await seedRiskAndRequiredLibraries();

  console.log('All tables created/verified.');

  initSocketIO(http.createServer(app));

  await startQueueSystem();

  const server = http.createServer(app);

  // Long local-LLM process calls need generous timeouts.
  server.timeout = 600_000;
  server.headersTimeout = 610_000;
  server.requestTimeout = 600_000;
  server.keepAliveTimeout = 120_000;

  server.listen(port, () => {
    console.log(`Legisense API listening on http://localhost:${port}`);
  });
}

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});

// Safety net: a single bad job must never take down the whole API.
process.on('uncaughtException', (err) => {
  console.error('[uncaughtException]', err);
});
process.on('unhandledRejection', (reason) => {
  console.error('[unhandledRejection]', reason);
});

process.on('SIGINT', async () => {
  await stopQueueSystem();
  await closeSocketIO();
  await closeDatabase();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await stopQueueSystem();
  await closeSocketIO();
  await closeDatabase();
  process.exit(0);
});
