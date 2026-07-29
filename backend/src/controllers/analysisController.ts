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
        status: docRows[0].processingStatus,
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
      res.json({ success: true, data: { categories: {}, items: [] } });
      return;
    }

    const riskRows = db.select().from(riskItems).where(
      sql`${riskItems.analysisId} = ${analysisRows[0].id}`
    ).all();

    const categories: Record<string, { count: number; severity: string }> = {};
    for (const r of riskRows) {
      const cat = r.riskType || 'other';
      if (!categories[cat]) {
        categories[cat] = { count: 0, severity: 'low' };
      }
      categories[cat].count++;
      const severityOrder = ['low', 'medium', 'high', 'critical'];
      const currentIdx = severityOrder.indexOf(categories[cat].severity);
      const itemIdx = severityOrder.indexOf(r.severity);
      if (itemIdx > currentIdx) {
        categories[cat].severity = r.severity;
      }
    }

    res.json({ success: true, data: { categories, items: riskRows } });
  } catch (err) {
    next(err);
  }
}

export async function getRisksByCategory(
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
    const category = req.params.category;
    const db = getDb();

    const docRows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    ).all();

    if (!docRows[0]) throw new NotFoundError('Document');

    const analysisRows = db.select().from(analysisResults).where(
      sql`${analysisResults.documentId} = ${documentId}`
    ).all();

    if (!analysisRows[0]) {
      res.json({ success: true, data: { category, clauses: [] } });
      return;
    }

    const clauseRows = db.select().from(clauses).where(
      sql`${clauses.analysisId} = ${analysisRows[0].id} AND ${clauses.riskCategory} = ${category}`
    ).all();

    res.json({ success: true, data: { category, clauses: clauseRows } });
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

export async function getRiskDashboard(
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
      res.json({ success: true, data: { overallScore: null, riskLevel: null, clauseCountByRisk: null, highestRiskClause: null, riskTrend: [] } });
      return;
    }

    const clauseRows = db.select().from(clauses).where(
      sql`${clauses.analysisId} = ${analysis.id}`
    ).all();

    const clauseCountByRisk = { high: 0, medium: 0, low: 0 };
    let highestRiskClause: Record<string, unknown> | null = null;
    let maxScore = -1;

    for (const c of clauseRows) {
      const level = c.riskLevel || 'low';
      if (level === 'high') clauseCountByRisk.high++;
      else if (level === 'medium') clauseCountByRisk.medium++;
      else clauseCountByRisk.low++;

      if ((c.riskScore ?? 0) > maxScore) {
        maxScore = c.riskScore ?? 0;
        highestRiskClause = {
          clauseNumber: c.clauseNumber,
          clauseTitle: c.clauseTitle,
          riskScore: c.riskScore,
          riskLevel: c.riskLevel,
        };
      }
    }

    const pastAnalyses = db.select({
      documentId: analysisResults.documentId,
      overallRiskScore: analysisResults.overallRiskScore,
      riskLevel: analysisResults.riskLevel,
      createdAt: analysisResults.createdAt,
    }).from(analysisResults)
      .where(
        sql`${analysisResults.userId} = ${req.user.id} AND ${analysisResults.documentId} != ${documentId}`
      )
      .orderBy(sql`${analysisResults.createdAt} ASC`)
      .all();

    const riskTrend = pastAnalyses.map((r) => ({
      documentId: r.documentId,
      overallRiskScore: r.overallRiskScore,
      riskLevel: r.riskLevel,
      analyzedAt: r.createdAt,
    }));

    res.json({
      success: true,
      data: {
        overallScore: analysis.overallRiskScore,
        riskLevel: analysis.riskLevel,
        clauseCountByRisk,
        highestRiskClause,
        riskTrend,
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
