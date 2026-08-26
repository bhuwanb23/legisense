import { Request, Response, NextFunction } from 'express';
import { getDb } from '../config/database';
import { notifications } from '../models';
import { sql } from 'drizzle-orm';
import { NotFoundError } from '../utils/errors';
import { persistNow } from '../config/database';

export async function listNotifications(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const db = getDb();
    const rows = await db.select().from(notifications).where(
      sql`${notifications.userId} = ${req.user.id}`
    );

    // Sort by createdAt descending (newest first)
    rows.sort((a, b) => {
      if (a.createdAt > b.createdAt) return -1;
      if (a.createdAt < b.createdAt) return 1;
      return 0;
    });

    const unreadCount = rows.filter((n) => !n.isRead).length;

    res.json({
      success: true,
      data: {
        notifications: rows.map((n) => ({
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          documentId: n.documentId,
          isRead: n.isRead,
          actionUrl: n.actionUrl,
          createdAt: n.createdAt,
        })),
        unreadCount,
        total: rows.length,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function markRead(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const notificationId = Number(req.params.id);
    const db = getDb();

    const rows = await db.select().from(notifications).where(
      sql`${notifications.id} = ${notificationId} AND ${notifications.userId} = ${req.user.id}`
    );

    if (!rows[0]) throw new NotFoundError('Notification');

    await db.execute(
      sql`UPDATE ${notifications} SET is_read = TRUE WHERE id = ${notificationId}`
    );

    persistNow();

    res.json({ success: true, data: { message: 'Notification marked as read', id: notificationId } });
  } catch (err) {
    next(err);
  }
}

export async function markAllRead(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const db = getDb();

    await db.execute(
      sql`UPDATE ${notifications} SET is_read = TRUE WHERE user_id = ${req.user.id} AND is_read = FALSE`
    );

    persistNow();

    res.json({ success: true, data: { message: 'All notifications marked as read' } });
  } catch (err) {
    next(err);
  }
}
