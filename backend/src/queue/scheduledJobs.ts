import { getDb, persistNow } from '../config/database';
import { documents, deadlines } from '../models';
import { sql } from 'drizzle-orm';
import { deleteFile } from '../storage/fileStorage';
import { createNotification } from '../services/notificationService';

export async function deleteExpiredDocuments(): Promise<void> {
  try {
    const db = getDb();

    const expired = db.select({
      id: documents.id,
      storagePath: documents.storagePath,
    }).from(documents)
      .where(
        sql`${documents.autoDeleteAt} IS NOT NULL
            AND ${documents.autoDeleteAt} < datetime('now')
            AND ${documents.isDeleted} = 0`
      ).all();

    if (expired.length === 0) return;

    for (const doc of expired) {
      try {
        await deleteFile(doc.storagePath);
      } catch {
        // File may already be gone
      }

      db.run(sql`UPDATE ${documents}
        SET is_deleted = 1,
            raw_text = NULL,
            encryption_iv = NULL,
            updated_at = datetime('now')
        WHERE id = ${doc.id}`);
    }

    persistNow();
  } catch (err) {
    console.error('Auto-delete check failed:', err);
  }
}

export async function checkDeadlineReminders(): Promise<void> {
  try {
    const db = getDb();

    const soon = db.select({
      id: deadlines.id,
      title: deadlines.title,
      userId: deadlines.userId,
      dueDate: deadlines.dueDate,
      documentId: deadlines.documentId,
    }).from(deadlines)
      .where(
        sql`${deadlines.reminderSent} = 0
            AND ${deadlines.isCompleted} = 0
            AND ${deadlines.isDismissed} = 0
            AND ${deadlines.dueDate} <= datetime('now', '+3 days')
            AND (${deadlines.reminderDate} IS NULL OR ${deadlines.reminderDate} <= datetime('now'))`
      ).all();

    if (soon.length === 0) return;

    for (const deadline of soon) {
      db.run(sql`UPDATE ${deadlines} SET reminder_sent = 1 WHERE id = ${deadline.id}`);

      createNotification(
        deadline.userId,
        'deadline_reminder',
        `Deadline approaching: ${deadline.title}`,
        `Due on ${deadline.dueDate}`,
        deadline.documentId || undefined,
      );
    }

    persistNow();
  } catch (err) {
    console.error('Deadline reminder check failed:', err);
  }
}
