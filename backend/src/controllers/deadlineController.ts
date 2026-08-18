import { Request, Response, NextFunction } from 'express';
import { getDb, persistNow } from '../config/database';
import { deadlines, documents, users } from '../models';
import { sql } from 'drizzle-orm';
import { NotFoundError, BadRequestError } from '../utils/errors';
import { computeDeadlineHealth, buildDeadlineInputsFromAnalysis, saveDeadlinesForDocument } from '../services/deadlineService';
import { analysisResults, clauses } from '../models';
import { buildIcsCalendar } from '../services/icsExportService';

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
    calendarExported: d.calendarExported,
    exportedAt: d.exportedAt,
    reminderEnabled: d.reminderEnabled,
    reminderTimes: safeJson(d.reminderTimes, [7, 3, 1]),
    reminderChannels: safeJson(d.reminderChannels, ['push']),
    createdAt: d.createdAt,
  };
}

function safeJson<T>(raw: string | null | undefined, fallback: T): T {
  if (!raw) return fallback;
  try { return JSON.parse(raw) as T; } catch { return fallback; }
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

    filtered.sort((a, b) => a.dueDate.localeCompare(b.dueDate));

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
      overdue: 0, this_week: 1, this_month: 2, upcoming: 3,
      critical: 0, high: 1, medium: 2, low: 3,
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

    let rows = db.select().from(deadlines).where(
      sql`${deadlines.documentId} = ${documentId} AND ${deadlines.userId} = ${req.user.id}`
    ).all();

    const analysis = db.select().from(analysisResults).where(sql`${analysisResults.documentId} = ${documentId}`).all()[0];
    if (analysis) {
      let missing: unknown = [];
      try { missing = JSON.parse(analysis.missingClauses || '[]'); } catch { missing = []; }
      const clauseRows = db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysis.id}`).all();
      const extras = buildDeadlineInputsFromAnalysis({
        documentType: analysis.documentType || 'Other',
        detectedTypeConfidence: analysis.detectedTypeConfidence || 0,
        overallRiskScore: analysis.overallRiskScore || 0,
        riskLevel: (analysis.riskLevel as 'low' | 'medium' | 'high') || 'low',
        fairnessScore: analysis.fairnessScore || 50,
        favorsParty: analysis.favorsParty || 'Balanced',
        imbalanceReason: analysis.imbalanceReason || '',
        perCategoryFairness: {},
        summary: analysis.summary || '',
        keyParties: [],
        criticalDates: [],
        keyObligations: [],
        missingClauses: Array.isArray(missing) ? missing.map(String) : [],
        clauses: clauseRows.map((c) => ({
          clauseNumber: c.clauseNumber || 1,
          clauseTitle: c.clauseTitle || 'Clause',
          originalText: c.originalText || '',
          plainEnglishText: c.plainEnglishText || '',
          readingLevel: 'grade_8' as const,
          keyLegalTerms: [],
          riskLevel: (c.riskLevel as 'low' | 'medium' | 'high' | 'none') || 'low',
          riskScore: c.riskScore || 0,
          riskReason: c.riskReason || '',
          riskCategory: 'legal' as const,
          partyReferences: [],
          counterSuggestion: c.counterSuggestion || '',
        })),
        riskItems: [],
        deadlines: rows.map((d) => ({
          title: d.title,
          description: d.description || d.title,
          dueDate: d.dueDate,
          recurrence: (d.recurrence as 'one-time') || 'one-time',
          deadlineType: 'other' as const,
          partyResponsible: d.partyResponsible || '',
          consequenceIfMissed: d.consequenceIfMissed || '',
          isRecurring: Boolean(d.isRecurring),
        })),
        breachScenarios: [],
      });
      const have = new Set(rows.map((r) => `${r.dueDate.slice(0, 10)}|${r.title.toLowerCase()}`));
      const toAdd = extras.filter((e) => !have.has(`${e.dueDate.slice(0, 10)}|${e.title.toLowerCase()}`)
        && !rows.some((r) => r.dueDate.slice(0, 10) === e.dueDate.slice(0, 10) && /start|commencement/.test(r.title.toLowerCase()) && /start|commencement/.test(e.title.toLowerCase())));
      if (toAdd.length) {
        saveDeadlinesForDocument(documentId, req.user.id, toAdd);
        rows = db.select().from(deadlines).where(
          sql`${deadlines.documentId} = ${documentId} AND ${deadlines.userId} = ${req.user.id}`
        ).all();
      }
    }

    const seen = new Set<string>();
    rows = rows.filter((r) => {
      const key = `${r.dueDate.slice(0, 10)}|${/start|commencement|begin/.test(r.title.toLowerCase()) ? 'start' : /end|expir/.test(r.title.toLowerCase()) ? 'end' : r.title.toLowerCase()}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });

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

export async function exportDeadlinesIcs(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const deadlineIds = Array.isArray(req.body?.deadlineIds)
      ? req.body.deadlineIds.map(Number).filter((n: number) => Number.isFinite(n))
      : Array.isArray(req.body?.deadline_ids)
        ? req.body.deadline_ids.map(Number).filter((n: number) => Number.isFinite(n))
        : [];
    const documentId = req.body?.documentId ?? req.body?.document_id ?? req.query.documentId ?? req.query.document_id;

    const db = getDb();
    let rows = db.select().from(deadlines).where(
      sql`${deadlines.userId} = ${req.user.id}`
    ).all();

    if (deadlineIds.length > 0) {
      rows = rows.filter((d) => deadlineIds.includes(d.id));
    } else if (documentId) {
      rows = rows.filter((d) => d.documentId === Number(documentId));
    } else {
      throw new BadRequestError('Provide deadlineIds or documentId');
    }

    if (rows.length === 0) throw new NotFoundError('Deadline');

    const docs = db.select().from(documents).where(
      sql`${documents.userId} = ${req.user.id}`
    ).all();
    const docName = new Map(docs.map((d) => [d.id, d.originalName]));

    const alreadyExported = rows.filter((d) => d.calendarExported).length;
    const ics = buildIcsCalendar(rows.map((d) => ({
      id: d.id,
      title: d.title,
      description: d.description,
      dueDate: d.dueDate,
      consequenceIfMissed: d.consequenceIfMissed,
      documentName: docName.get(d.documentId) || null,
    })));

    const now = new Date().toISOString();
    for (const d of rows) {
      db.run(sql`UPDATE ${deadlines} SET calendar_exported = 1, exported_at = ${now} WHERE id = ${d.id}`);
    }
    persistNow();

    if (req.query.json === '1') {
      res.json({
        success: true,
        data: {
          ics,
          exportedCount: rows.length,
          alreadyExported,
        },
      });
      return;
    }

    res.setHeader('Content-Type', 'text/calendar; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="legisense-deadlines.ics"');
    res.setHeader('X-Already-Exported', String(alreadyExported));
    res.setHeader('X-Exported-Count', String(rows.length));
    res.send(ics);
  } catch (err) {
    next(err);
  }
}

export async function updateDeadlineReminders(
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

    const enabled = req.body?.reminderEnabled ?? req.body?.reminder_enabled;
    const times = req.body?.reminderTimes ?? req.body?.reminder_times;
    const channels = req.body?.reminderChannels ?? req.body?.reminder_channels;

    if (enabled !== undefined) {
      db.run(sql`UPDATE ${deadlines} SET reminder_enabled = ${enabled ? 1 : 0} WHERE id = ${deadlineId}`);
    }
    if (Array.isArray(times)) {
      const cleaned = times.map(Number).filter((n) => Number.isFinite(n) && n >= 0);
      db.run(sql`UPDATE ${deadlines} SET reminder_times = ${JSON.stringify(cleaned)} WHERE id = ${deadlineId}`);
    }
    if (Array.isArray(channels)) {
      const cleaned = channels.map(String).filter((c) => c === 'push' || c === 'email');
      if (cleaned.length === 0) throw new BadRequestError('reminderChannels must include push and/or email');
      db.run(sql`UPDATE ${deadlines} SET reminder_channels = ${JSON.stringify(cleaned)} WHERE id = ${deadlineId}`);
    }

    persistNow();
    const updated = db.select().from(deadlines).where(sql`${deadlines.id} = ${deadlineId}`).all()[0];
    res.json({ success: true, data: mapDeadline(updated) });
  } catch (err) {
    next(err);
  }
}
