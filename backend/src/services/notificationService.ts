import { getDb } from '../config/database';
import { notifications } from '../models';
import { sql } from 'drizzle-orm';
import { emitToUser } from './socketService';

export function createNotification(
  userId: number,
  type: string,
  title: string,
  body: string,
  documentId?: number,
): number {
  const db = getDb();

  db.insert(notifications).values({
    userId,
    type,
    title,
    body,
    documentId,
    isRead: false,
  }).run();

  const rows = db.all(sql`SELECT last_insert_rowid() as id`) as { id: number }[];
  const id = Number(rows[0]?.id ?? 0);

  emitToUser(userId, 'notification:new', { id, type, title, body, documentId });

  return id;
}
