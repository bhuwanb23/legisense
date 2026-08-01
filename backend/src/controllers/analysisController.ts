import { Request, Response, NextFunction } from 'express';
import { getDb } from '../config/database';
import { documents, analysisResults, clauses, riskItems, deadlines, glossary, jurisdictionFlags, clauseRiskFlags, riskPatterns, communityRiskFeedback } from '../models';
import { sql } from 'drizzle-orm';
import { analysisQueue } from '../queue';
import { NotFoundError, BadRequestError } from '../utils/errors';
import { classifyDocument } from '../services/analysisService';
import { getTypeEntry, getValidTypes } from '../data/documentTypes';
import { getFilteredStateConflicts } from '../services/conflictDetectionService';
import { parseUserJurisdiction } from '../services/jurisdictionCheckService';
import { users } from '../models';
import { persistNow } from '../config/database';

function applyJurisdictionToDocument(
  documentId: number,
  userId: number,
  body: Record<string, unknown>,
): void {
  const db = getDb();
  let countryCode = (body.country_code || body.countryCode || null) as string | null;
  let stateCode = (body.state_code || body.stateCode || null) as string | null;

  if (!countryCode) {
    const userRows = db.select().from(users).where(sql`${users.id} = ${userId}`).all();
    const parsed = parseUserJurisdiction(userRows[0]?.defaultJurisdiction);
    countryCode = parsed.countryCode;
    stateCode = stateCode || parsed.stateCode;
  }

  if (countryCode) {
    countryCode = String(countryCode).toUpperCase();
    stateCode = stateCode ? String(stateCode).toUpperCase() : null;
    db.run(sql`UPDATE ${documents} SET
      country_code = ${countryCode},
      state_code = ${stateCode},
      updated_at = datetime('now')
      WHERE id = ${documentId}`);
  }
}

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
      // Allow retry when the queued job already failed (stuck "processing" status).
      const job = (req as { query?: { force?: string } }).query?.force === '1'
        || (req.body && (req.body as { force?: boolean }).force === true);
      if (!job) {
        res.status(409).json({
          success: false,
          error: { message: 'Analysis already in progress', code: 'ALREADY_PROCESSING', statusCode: 409 },
        });
        return;
      }
      db.run(sql`UPDATE ${documents} SET
        processing_status = 'pending',
        updated_at = datetime('now')
        WHERE id = ${documentId}`);
    }

    if (rows[0].processingStatus === 'failed') {
      db.run(sql`UPDATE ${documents} SET
        processing_status = 'pending',
        updated_at = datetime('now')
        WHERE id = ${documentId}`);
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

    applyJurisdictionToDocument(documentId, req.user.id, req.body || {});

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

export async function getPlainEnglish(
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

    const clauseRows = db.select({
      id: clauses.id,
      clauseNumber: clauses.clauseNumber,
      clauseTitle: clauses.clauseTitle,
      originalText: clauses.originalText,
      plainEnglishText: clauses.plainEnglishText,
      readingLevel: clauses.readingLevel,
      keyLegalTerms: clauses.keyLegalTerms,
      riskLevel: clauses.riskLevel,
      riskScore: clauses.riskScore,
    }).from(clauses).where(
      sql`${clauses.analysisId} = ${analysisRows[0].id}`
    ).all();

    const clausesWithTerms = clauseRows.map((c) => ({
      ...c,
      keyLegalTerms: safeJsonParse(c.keyLegalTerms),
    }));

    res.json({ success: true, data: { clauses: clausesWithTerms } });
  } catch (err) {
    next(err);
  }
}

export async function lookupGlossary(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { term } = req.body;
    if (!term || typeof term !== 'string' || term.trim().length === 0) {
      res.status(400).json({ success: false, error: { message: 'Term is required', code: 'VALIDATION_ERROR', statusCode: 400 } });
      return;
    }

    const db = getDb();
    const trimmed = term.trim();

    const rows = db.select().from(glossary).where(
      sql`LOWER(${glossary.term}) = LOWER(${trimmed})`
    ).all();

    if (rows.length > 0) {
      res.json({
        success: true,
        data: {
          term: rows[0].term,
          definition: rows[0].definition,
          category: rows[0].category,
          source: 'cache',
        },
      });
      return;
    }

    const fuzzyRows = db.select().from(glossary).where(
      sql`LOWER(${glossary.term}) LIKE LOWER(${'%' + trimmed + '%'})`
    ).all();

    if (fuzzyRows.length > 0) {
      res.json({
        success: true,
        data: {
          term: fuzzyRows[0].term,
          definition: fuzzyRows[0].definition,
          category: fuzzyRows[0].category,
          source: 'cache',
        },
      });
      return;
    }

    const generatedDefinition = `"${trimmed}" is a legal term or concept. For an authoritative definition, please consult a legal professional or reference a standard legal dictionary.`;
    res.json({
      success: true,
      data: {
        term: trimmed,
        definition: generatedDefinition,
        category: 'unknown',
        source: 'ai',
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function classifyEndpoint(
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

    const rawText = docRows[0].rawText;
    if (!rawText || rawText.trim().length === 0) {
      res.status(400).json({ success: false, error: { message: 'Document text not available. Upload and extract text first.', code: 'NO_TEXT', statusCode: 400 } });
      return;
    }

    const classification = await classifyDocument(rawText);
    const typeEntry = getTypeEntry(classification.type);
    const needsConfirmation = classification.confidence < 60;

    res.json({
      success: true,
      data: {
        type: classification.type,
        typeLabel: typeEntry.typeLabel,
        confidence: classification.confidence,
        subType: classification.sub_type,
        icon: typeEntry.icon,
        needsConfirmation,
        supportedTypes: getValidTypes(),
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function confirmDocumentType(
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
    const { type } = req.body;

    if (!type || typeof type !== 'string') {
      res.status(400).json({ success: false, error: { message: 'Type is required', code: 'VALIDATION_ERROR', statusCode: 400 } });
      return;
    }

    const typeEntry = getTypeEntry(type);
    if (typeEntry.type === 'unknown' && type !== 'unknown') {
      res.status(400).json({ success: false, error: { message: `Unsupported type "${type}". Use one of: ${getValidTypes().join(', ')}`, code: 'INVALID_TYPE', statusCode: 400 } });
      return;
    }

    const db = getDb();
    const docRows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    ).all();

    if (!docRows[0]) throw new NotFoundError('Document');

    db.run(sql`UPDATE ${documents} SET
      detected_type = ${type},
      detected_type_confidence = 100,
      needs_type_confirmation = 0,
      updated_at = datetime('now')
      WHERE id = ${documentId}`);

    res.json({
      success: true,
      data: {
        documentId,
        type,
        typeLabel: typeEntry.typeLabel,
        confirmed: true,
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

export async function getJurisdictionFlags(
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
          jurisdiction_check_status: null,
          flags: { critical: [], warning: [], info: [] },
          total: 0,
        },
      });
      return;
    }

    const flags = db.select().from(jurisdictionFlags).where(
      sql`${jurisdictionFlags.documentId} = ${documentId}`
    ).all();

    const grouped = {
      critical: flags.filter((f) => f.severity === 'critical'),
      warning: flags.filter((f) => f.severity === 'warning'),
      info: flags.filter((f) => f.severity === 'info'),
    };

    res.json({
      success: true,
      data: {
        status: docRows[0].processingStatus,
        jurisdiction_check_status: analysis.jurisdictionCheckStatus,
        country_code: docRows[0].countryCode,
        state_code: docRows[0].stateCode,
        flags: grouped,
        total: flags.length,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function getStateConflicts(
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
    const conflicts = getFilteredStateConflicts(documentId, req.user.id);
    if (conflicts === null) throw new NotFoundError('Document');

    res.json({
      success: true,
      data: {
        documentId,
        conflicts,
        total: conflicts.length,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function getFlaggedClauses(
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

    const flags = db.select().from(clauseRiskFlags).where(
      sql`${clauseRiskFlags.documentId} = ${documentId}`
    ).all();
    const patterns = db.select().from(riskPatterns).all();
    const patternById = new Map(patterns.map((p) => [p.id, p]));
    const clauseRows = db.select().from(clauses).where(sql`${clauses.documentId} = ${documentId}`).all();
    const clauseById = new Map(clauseRows.map((c) => [c.id, c]));

    const byClause = new Map<number, {
      clause: typeof clauseRows[0];
      flags: Array<Record<string, unknown>>;
    }>();

    for (const f of flags) {
      const clause = clauseById.get(f.clauseId);
      if (!clause) continue;
      const pattern = patternById.get(f.patternId);
      const entry = byClause.get(f.clauseId) || { clause, flags: [] };
      entry.flags.push({
        id: f.id,
        match_type: f.matchType,
        match_confidence: f.matchConfidence,
        flagged_text_snippet: f.flaggedTextSnippet,
        pattern: pattern ? {
          id: pattern.id,
          name: pattern.patternName,
          category: pattern.patternCategory,
          severity: pattern.severity,
          explanation: pattern.explanation,
          recommendation: pattern.recommendation,
        } : null,
      });
      byClause.set(f.clauseId, entry);
    }

    const flagged = [...byClause.values()].map((v) => ({
      id: v.clause.id,
      clauseNumber: v.clause.clauseNumber,
      clauseTitle: v.clause.clauseTitle,
      originalText: v.clause.originalText,
      plainEnglishText: v.clause.plainEnglishText,
      riskScore: v.clause.riskScore,
      riskLevel: v.clause.riskLevel,
      patterns: v.flags,
    }));

    res.json({ success: true, data: { flaggedClauses: flagged, total: flagged.length } });
  } catch (err) {
    next(err);
  }
}

export async function submitRiskFeedback(
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
    const clauseId = Number(req.params.clauseId);
    const feedbackType = String(req.body?.feedback_type || req.body?.feedbackType || '');
    const patternId = req.body?.pattern_id ?? req.body?.patternId ?? null;
    const note = req.body?.note ? String(req.body.note) : null;

    if (!['mark_risky', 'mark_safe', 'wrong_flag'].includes(feedbackType)) {
      throw new BadRequestError('feedback_type must be mark_risky, mark_safe, or wrong_flag');
    }

    const db = getDb();
    const docRows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id}`
    ).all();
    if (!docRows[0]) throw new NotFoundError('Document');

    const clauseRows = db.select().from(clauses).where(
      sql`${clauses.id} = ${clauseId} AND ${clauses.documentId} = ${documentId}`
    ).all();
    if (!clauseRows[0]) throw new NotFoundError('Clause');

    db.insert(communityRiskFeedback).values({
      userId: req.user.id,
      documentId,
      clauseId,
      patternId: patternId ? Number(patternId) : null,
      feedbackType,
      note,
    }).run();

    if (feedbackType === 'mark_risky') {
      db.run(sql`UPDATE ${clauses} SET is_flagged = 1 WHERE id = ${clauseId}`);
    }

    persistNow();
    res.status(201).json({ success: true, data: { message: 'Feedback recorded' } });
  } catch (err) {
    next(err);
  }
}

export async function getMissingClausesEndpoint(
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
      res.json({ success: true, data: { missing: { critical: [], recommended: [], optional: [] }, incomplete: [], total: 0 } });
      return;
    }

    const raw = safeJsonParse(analysisRows[0].missingClauses);
    const list = Array.isArray(raw) ? raw : [];

    const structured = list.map((item: unknown) => {
      if (typeof item === 'string') {
        return { name: item, importance: 'recommended', why_needed: '', is_confirmed_missing: true, is_incomplete: false };
      }
      return item as Record<string, unknown>;
    });

    const incomplete = structured.filter((i) => i.is_incomplete);
    const missingOnly = structured.filter((i) => !i.is_incomplete);

    res.json({
      success: true,
      data: {
        missing: {
          critical: missingOnly.filter((i) => i.importance === 'critical'),
          recommended: missingOnly.filter((i) => i.importance === 'recommended'),
          optional: missingOnly.filter((i) => i.importance === 'optional'),
        },
        incomplete,
        total: structured.length,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function getCounterClauses(
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
    const status = analysisRows[0]?.counterClausesStatus || 'skipped';

    const clauseRows = db.select().from(clauses).where(sql`${clauses.documentId} = ${documentId}`).all()
      .filter((c) => {
        const score = c.riskScore ?? 0;
        const level = (c.riskLevel || '').toLowerCase();
        const hasSuggestion = Boolean(c.counterSuggestion && c.counterSuggestion.trim());
        return hasSuggestion && (score > 50 || level === 'high' || level === 'medium');
      });

    res.json({
      success: true,
      data: {
        status,
        clauses: clauseRows.map((c) => ({
          id: c.id,
          clauseNumber: c.clauseNumber,
          clauseTitle: c.clauseTitle,
          originalText: c.originalText,
          riskScore: c.riskScore,
          riskLevel: c.riskLevel,
          riskReason: c.riskReason,
          counterSuggestion: c.counterSuggestion,
          negotiationTips: safeJsonParse(c.negotiationTips),
          usedCounter: c.usedCounter,
          copiedAt: c.copiedAt,
        })),
        total: clauseRows.length,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function markCounterUsed(
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
    const clauseId = Number(req.params.clauseId);
    const db = getDb();

    const docRows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id}`
    ).all();
    if (!docRows[0]) throw new NotFoundError('Document');

    const clauseRows = db.select().from(clauses).where(
      sql`${clauses.id} = ${clauseId} AND ${clauses.documentId} = ${documentId}`
    ).all();
    if (!clauseRows[0]) throw new NotFoundError('Clause');

    const now = new Date().toISOString();
    db.run(sql`UPDATE ${clauses} SET used_counter = 1, copied_at = ${now} WHERE id = ${clauseId}`);
    persistNow();

    res.json({ success: true, data: { clauseId, usedCounter: true, copiedAt: now } });
  } catch (err) {
    next(err);
  }
}


export async function rewritePlainEnglish(
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

    const { readingLevel } = req.body;
    if (!readingLevel || !['grade5', 'grade8', 'standard'].includes(readingLevel)) {
      throw new BadRequestError('readingLevel must be grade5, grade8, or standard');
    }

    const db = getDb();
    const docRows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    ).all();

    if (!docRows[0]) throw new NotFoundError('Document');

    const analysisRows = db.select().from(analysisResults).where(
      sql`${analysisResults.documentId} = ${documentId}`
    ).all();

    if (!analysisRows[0]) throw new NotFoundError('Analysis not found for this document');

    const clauseRows = db.select().from(clauses).where(
      sql`${clauses.analysisId} = ${analysisRows[0].id}`
    ).all();

    const readingLevelMap: Record<string, string> = {
      grade5: 'grade_5',
      grade8: 'grade_8',
      standard: 'standard',
    };

    const levelLabel = readingLevelMap[readingLevel];
    const { getAiProvider } = await import('../services/ai/aiProviderService');
    const aiProvider = getAiProvider();

    for (const clause of clauseRows) {
      const levelDesc = readingLevel === 'grade5' ? 'Grade 5 (age 10-11)' : readingLevel === 'grade8' ? 'Grade 8 (age 13-14)' : 'standard college';
      const prompt = `Rewrite the following legal text at a ${levelDesc} reading level. Keep it simple, clear, and use short sentences. Do not lose legal meaning.\n\nOriginal: ${clause.originalText || clause.plainEnglishText}\n\nRewritten:`;

      try {
        const response = await aiProvider.generate(prompt);
        const plainEnglishText = response.trim();

        db.run(
          sql`UPDATE ${clauses} SET plain_english_text = ${plainEnglishText}, reading_level = ${levelLabel} WHERE id = ${clause.id}`
        );
      } catch (err) {
        console.error(`Failed to rewrite clause ${clause.id}:`, err);
      }
    }

    persistNow();

    const updatedClauseRows = db.select().from(clauses).where(
      sql`${clauses.analysisId} = ${analysisRows[0].id}`
    ).all();

    res.json({
      success: true,
      data: {
        message: `Clauses rewritten at ${readingLevel} level`,
        clauses: updatedClauseRows.map((c) => ({
          id: c.id,
          clauseTitle: c.clauseTitle,
          plainEnglishText: c.plainEnglishText,
          readingLevel: c.readingLevel,
        })),
      },
    });
  } catch (err) {
    next(err);
  }
}
