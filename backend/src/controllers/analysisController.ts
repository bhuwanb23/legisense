import { Request, Response, NextFunction } from 'express';
import { getDb } from '../config/database';
import { documents, analysisResults, clauses, riskItems, deadlines } from '../models';
import { sql } from 'drizzle-orm';
import { analysisQueue } from '../queue';
import { NotFoundError, BadRequestError } from '../utils/errors';

export async function startAnalysis(
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
    if (!documentId) throw new BadRequestError('Invalid document ID');

    const db = getDb();
    const rows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    ).all();

    if (!rows[0]) throw new NotFoundError('Document');

    if (rows[0].processingStatus === 'processing') {
      res.status(409).json({
        success: false,
        error: { message: 'Analysis already in progress', code: 'ALREADY_PROCESSING', statusCode: 409 },
      });
      return;
    }

    const existingAnalysis = db.select().from(analysisResults).where(
      sql`${analysisResults.documentId} = ${documentId}`
    ).all();

    if (existingAnalysis.length > 0) {
      res.status(409).json({
        success: false,
        error: { message: 'Analysis already completed for this document. Use GET to view results.', code: 'ANALYSIS_EXISTS', statusCode: 409 },
      });
      return;
    }

    db.run(
      sql`UPDATE ${documents} SET processing_status = 'pending', updated_at = datetime('now') WHERE id = ${documentId}`
    );

    const job = await analysisQueue.add('analyze', { documentId, userId: req.user.id });

    res.status(202).json({
      success: true,
      data: {
        documentId,
        status: 'pending',
        jobId: job.id,
        message: 'Analysis queued. Check status with GET /api/analysis/:documentId',
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function getAnalysis(
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

    const analysisRows = db.select().from(analysisResults).where(
      sql`${analysisResults.documentId} = ${documentId}`
    ).all();

    const analysis = analysisRows[0];
    if (!analysis) {
      res.json({
        success: true,
        data: {
          status: docRows[0].processingStatus,
          analysis: null,
        },
      });
      return;
    }

    res.json({
      success: true,
      data: {
        status: 'completed',
        analysis: {
          ...analysis,
          keyParties: safeJsonParse(analysis.keyParties),
          criticalDates: safeJsonParse(analysis.criticalDates),
          keyObligations: safeJsonParse(analysis.keyObligations),
          missingClauses: safeJsonParse(analysis.missingClauses),
          jurisdictionFlags: safeJsonParse(analysis.jurisdictionFlags),
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function getClauses(
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

    const analysisRows = db.select().from(analysisResults).where(
      sql`${analysisResults.documentId} = ${documentId}`
    ).all();

    if (!analysisRows[0]) {
      res.json({ success: true, data: { clauses: [] } });
      return;
    }

    const clauseRows = db.select().from(clauses).where(
      sql`${clauses.analysisId} = ${analysisRows[0].id}`
    ).all();

    res.json({ success: true, data: { clauses: clauseRows } });
  } catch (err) {
    next(err);
  }
}

export async function getRisks(
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

    const analysisRows = db.select().from(analysisResults).where(
      sql`${analysisResults.documentId} = ${documentId}`
    ).all();

    if (!analysisRows[0]) {
      res.json({ success: true, data: { riskItems: [] } });
      return;
    }

    const riskRows = db.select().from(riskItems).where(
      sql`${riskItems.analysisId} = ${analysisRows[0].id}`
    ).all();

    res.json({ success: true, data: { riskItems: riskRows } });
  } catch (err) {
    next(err);
  }
}

export async function getSummary(
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

    const analysisRows = db.select().from(analysisResults).where(
      sql`${analysisResults.documentId} = ${documentId}`
    ).all();

    const analysis = analysisRows[0];

    res.json({
      success: true,
      data: {
        status: docRows[0].processingStatus,
        summary: analysis?.summary || null,
        documentType: analysis?.documentType || null,
        overallRiskScore: analysis?.overallRiskScore ?? null,
        riskLevel: analysis?.riskLevel || null,
        fairnessScore: analysis?.fairnessScore ?? null,
        favorsParty: analysis?.favorsParty || null,
      },
    });
  } catch (err) {
    next(err);
  }
}

function safeJsonParse(value: string | null): unknown {
  if (!value) return [];
  try { return JSON.parse(value); } catch { return []; }
}
