import { getDb } from '../config/database';
import { notifications } from '../models';
import { sql } from 'drizzle-orm';
import { emitToUser } from './socketService';

export async function createNotification(
  userId: number,
  type: string,
  title: string,
  body: string,
  documentId?: number,
): Promise<number> {
  const db = getDb();

  await db.insert(notifications).values({
    userId,
    type,
    title,
    body,
    documentId,
    isRead: false,
  });

  const rows = (await db.execute(sql`SELECT id as id`)).rows as { id: number }[];
  const id = Number(rows[0]?.id ?? 0);

  emitToUser(userId, 'notification:new', { id, type, title, body, documentId });

  return id;
}
