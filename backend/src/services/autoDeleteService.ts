import { getDb, persistNow } from '../config/database';
import { documents } from '../models';
import { sql } from 'drizzle-orm';
import { deleteFile } from '../storage/fileStorage';

const CHECK_INTERVAL_MS = 60 * 60 * 1000;

let intervalHandle: ReturnType<typeof setInterval> | null = null;

export function startAutoDeleteService(): void {
  runAutoDeleteCheck();
  intervalHandle = setInterval(runAutoDeleteCheck, CHECK_INTERVAL_MS);
  console.log(`Auto-delete service started (checking every ${CHECK_INTERVAL_MS / 60000} min)`);
}

export function stopAutoDeleteService(): void {
  if (intervalHandle) {
    clearInterval(intervalHandle);
    intervalHandle = null;
  }
}

async function runAutoDeleteCheck(): Promise<void> {
  try {
    const db = getDb();

    const expired = await db.select({
      id: documents.id,
      storagePath: documents.storagePath,
    }).from(documents)
      .where(
        sql`${documents.autoDeleteAt} IS NOT NULL
            AND ${documents.autoDeleteAt}::timestamptz < NOW()
            AND ${documents.isDeleted} = 0`
      );

    if (expired.length === 0) return;

    for (const doc of expired) {
      try {
        await deleteFile(doc.storagePath);
      } catch {
        // File may already be gone — continue
      }

      await db.execute(sql`UPDATE ${documents}
        SET is_deleted = 1,
            raw_text = NULL,
            encryption_iv = NULL,
            updated_at = NOW()
        WHERE id = ${doc.id}`);

      console.log(`Auto-deleted document ${doc.id} (file: ${doc.storagePath})`);
    }

    persistNow();
  } catch (err) {
    console.error('Auto-delete check failed:', err);
  }
}
