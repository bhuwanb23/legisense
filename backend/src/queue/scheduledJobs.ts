import { getDb, persistNow } from '../config/database';
import { documents, deadlines, users } from '../models';
import { sql } from 'drizzle-orm';
import { deleteFile } from '../storage/fileStorage';
import { createNotification } from '../services/notificationService';
import { isSmtpConfigured, sendReminderEmail } from '../services/emailService';

export async function deleteExpiredDocuments(): Promise<void> {
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
        // File may already be gone
      }

      await db.execute(sql`UPDATE ${documents}
        SET is_deleted = 1,
            raw_text = NULL,
            encryption_iv = NULL,
            updated_at = NOW()
        WHERE id = ${doc.id}`);
    }

    persistNow();
  } catch (err) {
    console.error('Auto-delete check failed:', err);
  }
}

export function daysUntilDue(dueDateStr: string, today = new Date()): number {
  const due = new Date(dueDateStr.slice(0, 10) + 'T12:00:00');
  if (isNaN(due.getTime())) return Number.POSITIVE_INFINITY;
  const start = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const dueDay = new Date(due.getFullYear(), due.getMonth(), due.getDate());
  return Math.round((dueDay.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
}

export function shouldSendReminder(
  daysUntil: number,
  reminderTimes: number[],
  alreadySentDays: number[],
): boolean {
  return reminderTimes.includes(daysUntil) && !alreadySentDays.includes(daysUntil);
}

export async function checkDeadlineReminders(): Promise<void> {
  try {
    const db = getDb();

    const active = await db.select().from(deadlines).where(
      sql`${deadlines.isCompleted} = 0
          AND ${deadlines.isDismissed} = 0`
    );

    for (const deadline of active) {
      const enabled = deadline.reminderEnabled !== false;
      if (!enabled) continue;

      let times: number[] = [7, 3, 1];
      try {
        const parsed = JSON.parse(deadline.reminderTimes || '[7,3,1]');
        if (Array.isArray(parsed)) times = parsed.map(Number).filter((n) => Number.isFinite(n));
      } catch { /* keep default */ }

      let sentDays: number[] = [];
      try {
        const parsed = JSON.parse(deadline.reminderSentDays || '[]');
        if (Array.isArray(parsed)) sentDays = parsed.map(Number).filter((n) => Number.isFinite(n));
      } catch { /* keep empty */ }

      let channels: string[] = ['push'];
      try {
        const parsed = JSON.parse(deadline.reminderChannels || '["push"]');
        if (Array.isArray(parsed)) channels = parsed.map(String);
      } catch { /* keep default */ }

      const daysUntil = daysUntilDue(deadline.dueDate);
      if (!shouldSendReminder(daysUntil, times, sentDays)) continue;

      const docRows = await db.select().from(documents).where(sql`${documents.id} = ${deadline.documentId}`);
      const docName = docRows[0]?.originalName || 'Document';

      const whenLabel = daysUntil === 0
        ? 'today'
        : daysUntil < 0
          ? `${Math.abs(daysUntil)} day(s) overdue`
          : `in ${daysUntil} day(s)`;

      if (channels.includes('push')) {
        createNotification(
          deadline.userId,
          'deadline_reminder',
          `Reminder: ${deadline.title}`,
          `Due ${whenLabel} (${deadline.dueDate}). ${deadline.consequenceIfMissed || ''}`.trim(),
          deadline.documentId || undefined,
        );
      }

      if (channels.includes('email') && isSmtpConfigured()) {
        const userRows = await db.select().from(users).where(sql`${users.id} = ${deadline.userId}`);
        const email = userRows[0]?.email;
        if (email) {
          await sendReminderEmail({
            to: email,
            title: deadline.title,
            dueDate: deadline.dueDate,
            daysUntil,
            documentName: docName,
            consequence: deadline.consequenceIfMissed || undefined,
          });
        }
      }

      sentDays.push(daysUntil);
      await db.execute(sql`UPDATE ${deadlines} SET
        reminder_sent = 1,
        reminder_sent_days = ${JSON.stringify(sentDays)},
        reminder_date = NOW()
        WHERE id = ${deadline.id}`);
    }

    persistNow();
  } catch (err) {
    console.error('Deadline reminder check failed:', err);
  }
}
