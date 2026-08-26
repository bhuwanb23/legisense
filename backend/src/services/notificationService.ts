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

  const inserted = await db.insert(notifications).values({
    userId,
    type,
    title,
    body,
    documentId,
    isRead: false,
  }).returning({ id: notifications.id });

  const id = Number(inserted[0]?.id ?? 0);

  emitToUser(userId, 'notification:new', { id, type, title, body, documentId });

  return id;
}
