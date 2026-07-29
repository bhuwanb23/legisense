import { initDatabase, closeDatabase } from '../src/config/database';
import { getDb } from '../src/config/database';
import { Queue } from '../src/queue';

async function main() {
  process.env.JWT_SECRET = 'test-secret';
  await initDatabase();

  const queue = new Queue('debug-filter');
  await queue.add('a', {});

  const db = getDb();
  const rows = db.all(`SELECT * FROM jobs WHERE queue_name = 'debug-filter'`);
  console.log('rows:', JSON.stringify(rows, null, 2));
  console.log('rows[0] keys:', Object.keys(rows[0]));

  const jobs = await queue.getJobs(['pending']);
  console.log('filtered jobs:', JSON.stringify(jobs, null, 2));
  console.log('filtered count:', jobs.length);

  await queue.obliterate();
  closeDatabase();
}

main().catch(console.error);
