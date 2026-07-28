import { Request, Response, NextFunction } from 'express';
import { getDb } from '../config/database';
import { deadlines } from '../models';
import { sql } from 'drizzle-orm';
import { NotFoundError } from '../utils/errors';
import { persistNow } from '../config/database';

export async function listDeadlines(
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
    const rows = db.select().from(deadlines).where(
      sql`${deadlines.userId} = ${req.user.id}`
    ).all();

    const completed = req.query.completed as string | undefined;
    let filtered = rows;
    if (completed === 'true') {
      filtered = rows.filter((d) => d.isCompleted);
    } else if (completed === 'false') {
      filtered = rows.filter((d) => !d.isCompleted);
    }

    // Sort by due date ascending
    filtered.sort((a, b) => {
      if (a.dueDate < b.dueDate) return -1;
      if (a.dueDate > b.dueDate) return 1;
      return 0;
    });

    res.json({
      success: true,
      data: {
        deadlines: filtered.map((d) => ({
          id: d.id,
          documentId: d.documentId,
          title: d.title,
          description: d.description,
          dueDate: d.dueDate,
          recurrence: d.recurrence,
          urgencyLevel: d.urgencyLevel,
          isCompleted: d.isCompleted,
          isDismissed: d.isDismissed,
          createdAt: d.createdAt,
        })),
        total: filtered.length,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function completeDeadline(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const deadlineId = Number(req.params.id);
    const db = getDb();

    const rows = db.select().from(deadlines).where(
      sql`${deadlines.id} = ${deadlineId} AND ${deadlines.userId} = ${req.user.id}`
    ).all();

    if (!rows[0]) throw new NotFoundError('Deadline');

    db.run(
      sql`UPDATE ${deadlines} SET is_completed = 1 WHERE id = ${deadlineId}`
    );

    persistNow();

    res.json({ success: true, data: { message: 'Deadline marked as completed', id: deadlineId } });
  } catch (err) {
    next(err);
  }
}

export async function dismissDeadline(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const deadlineId = Number(req.params.id);
    const db = getDb();

    const rows = db.select().from(deadlines).where(
      sql`${deadlines.id} = ${deadlineId} AND ${deadlines.userId} = ${req.user.id}`
    ).all();

    if (!rows[0]) throw new NotFoundError('Deadline');

    db.run(
      sql`UPDATE ${deadlines} SET is_dismissed = 1 WHERE id = ${deadlineId}`
    );

    persistNow();

    res.json({ success: true, data: { message: 'Deadline dismissed', id: deadlineId } });
  } catch (err) {
    next(err);
  }
}
