import { Request, Response, NextFunction } from 'express';
import { getDb, persistNow } from '../config/database';
import { deadlines, documents } from '../models';
import { sql } from 'drizzle-orm';
import { NotFoundError } from '../utils/errors';
import { computeDeadlineHealth } from '../services/deadlineService';

function mapDeadline(d: typeof deadlines.$inferSelect) {
  return {
    id: d.id,
    documentId: d.documentId,
    title: d.title,
    description: d.description,
    dueDate: d.dueDate,
    recurrence: d.recurrence,
    urgencyLevel: d.urgencyLevel,
    deadlineType: d.deadlineType,
    partyResponsible: d.partyResponsible,
    consequenceIfMissed: d.consequenceIfMissed,
    isRecurring: d.isRecurring,
    parentId: d.parentId,
    isCompleted: d.isCompleted,
    isDismissed: d.isDismissed,
    createdAt: d.createdAt,
  };
}

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

    filtered.sort((a, b) => {
      if (a.dueDate < b.dueDate) return -1;
      if (a.dueDate > b.dueDate) return 1;
      return 0;
    });

    res.json({
      success: true,
      data: {
        deadlines: filtered.map(mapDeadline),
        total: filtered.length,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function listUpcomingDeadlines(
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
    ).all()
      .filter((d) => !d.isCompleted && !d.isDismissed);

    const urgencyRank: Record<string, number> = {
      overdue: 0,
      this_week: 1,
      this_month: 2,
      upcoming: 3,
      critical: 0,
      high: 1,
      medium: 2,
      low: 3,
    };

    rows.sort((a, b) => {
      const ra = urgencyRank[a.urgencyLevel || 'upcoming'] ?? 3;
      const rb = urgencyRank[b.urgencyLevel || 'upcoming'] ?? 3;
      if (ra !== rb) return ra - rb;
      return a.dueDate.localeCompare(b.dueDate);
    });

    res.json({
      success: true,
      data: {
        deadlines: rows.map(mapDeadline),
        total: rows.length,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function listDocumentDeadlines(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const documentId = Number(req.params.documentId);
    const db = getDb();

    const docRows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    ).all();
    if (!docRows[0]) throw new NotFoundError('Document');

    const rows = db.select().from(deadlines).where(
      sql`${deadlines.documentId} = ${documentId} AND ${deadlines.userId} = ${req.user.id}`
    ).all();

    rows.sort((a, b) => a.dueDate.localeCompare(b.dueDate));
    const health = computeDeadlineHealth(rows);

    res.json({
      success: true,
      data: {
        documentId,
        deadlines: rows.map(mapDeadline),
        health,
        total: rows.length,
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

    db.run(sql`UPDATE ${deadlines} SET is_completed = 1 WHERE id = ${deadlineId}`);
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

    db.run(sql`UPDATE ${deadlines} SET is_dismissed = 1 WHERE id = ${deadlineId}`);
    persistNow();

    res.json({ success: true, data: { message: 'Deadline dismissed', id: deadlineId } });
  } catch (err) {
    next(err);
  }
}
