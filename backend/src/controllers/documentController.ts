import { Request, Response, NextFunction } from 'express';
import { getDb } from '../config/database';
import { documents, analysisResults, clauses, riskItems, deadlines } from '../models';
import { sql } from 'drizzle-orm';
import { saveFile } from '../storage/fileStorage';
import { queueService } from '../services/queueService';
import { NotFoundError } from '../utils/errors';
import { persistNow } from '../config/database';

export async function uploadDocument(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    if (!req.file) {
      res.status(400).json({ success: false, error: { message: 'No file uploaded', code: 'NO_FILE', statusCode: 400 } });
      return;
    }

    const { originalname, buffer } = req.file;
    const format = originalname.split('.').pop()?.toLowerCase() || 'unknown';

    const storagePath = saveFile(buffer, originalname, format);

    const db = getDb();
    const sourceType = req.body.source_type || 'file_upload';

    db.insert(documents).values({
      userId: req.user.id,
      originalName: originalname,
      storagePath,
      fileFormat: format,
      fileSize: buffer.length,
      sourceType,
      uploadStatus: 'uploaded',
      processingStatus: 'pending',
    }).run();

    const allDocs = db.select().from(documents).where(sql`${documents.storagePath} = ${storagePath}`).all();
    const doc = allDocs[0];

    if (!doc) {
      throw new Error('Failed to create document record');
    }

    persistNow();

    const job = queueService.enqueue(doc.id, req.user.id);

    res.status(202).json({
      success: true,
      data: {
        documentId: doc.id,
        originalName: doc.originalName,
        fileFormat: doc.fileFormat,
        fileSize: doc.fileSize,
        uploadStatus: doc.uploadStatus,
        processingStatus: 'pending',
        jobId: job.id,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function listDocuments(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const page = Number(req.query.page) || 1;
    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const offset = (page - 1) * limit;
    const status = (req.query.status as string) || 'all';

    const db = getDb();

    let whereClause = sql`${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`;
    if (status !== 'all') {
      whereClause = sql`${whereClause} AND ${documents.processingStatus} = ${status}`;
    }

    const countRows = db.all(
      sql`SELECT COUNT(*) as total FROM documents WHERE user_id = ${req.user.id} AND is_deleted = 0`
    ) as Array<{ total: number }>;
    const total = countRows[0]?.total || 0;

    const rows = db.select().from(documents).where(whereClause).all();

    const paginated = rows.slice(offset, offset + limit);

    res.json({
      success: true,
      data: {
        documents: paginated.map((doc) => ({
          id: doc.id,
          originalName: doc.originalName,
          fileFormat: doc.fileFormat,
          fileSize: doc.fileSize,
          sourceType: doc.sourceType,
          uploadStatus: doc.uploadStatus,
          processingStatus: doc.processingStatus,
          createdAt: doc.createdAt,
        })),
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function getDocument(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const documentId = Number(req.params.id);
    const db = getDb();

    const rows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    ).all();

    const doc = rows[0];
    if (!doc) {
      throw new NotFoundError('Document');
    }

    res.json({
      success: true,
      data: {
        id: doc.id,
        originalName: doc.originalName,
        fileFormat: doc.fileFormat,
        fileSize: doc.fileSize,
        sourceType: doc.sourceType,
        sourceUrl: doc.sourceUrl,
        uploadStatus: doc.uploadStatus,
        processingStatus: doc.processingStatus,
        pageCount: doc.pageCount,
        detectedLanguage: doc.detectedLanguage,
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function deleteDocument(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const documentId = Number(req.params.id);
    const db = getDb();

    const rows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    ).all();

    if (!rows[0]) {
      throw new NotFoundError('Document');
    }

    db.run(
      sql`UPDATE ${documents} SET is_deleted = 1, updated_at = datetime('now') WHERE id = ${documentId}`
    );

    persistNow();

    res.json({
      success: true,
      data: { message: 'Document deleted successfully' },
    });
  } catch (err) {
    next(err);
  }
}

export async function pasteText(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const { text, title } = req.body;
    const docTitle = title || 'Pasted Text';
    const storagePath = saveFile(Buffer.from(text, 'utf-8'), `${docTitle}.txt`, 'txt');

    const db = getDb();

    db.insert(documents).values({
      userId: req.user.id,
      originalName: docTitle,
      storagePath,
      fileFormat: 'txt',
      fileSize: Buffer.byteLength(text, 'utf-8'),
      sourceType: 'paste',
      rawText: text,
      uploadStatus: 'uploaded',
      processingStatus: 'pending',
    }).run();

    const allDocs = db.select().from(documents).where(sql`${documents.storagePath} = ${storagePath}`).all();
    const doc = allDocs[0];

    if (!doc) {
      throw new Error('Failed to create document record');
    }

    persistNow();

    const job = queueService.enqueue(doc.id, req.user.id);

    res.status(202).json({
      success: true,
      data: {
        documentId: doc.id,
        originalName: doc.originalName,
        fileFormat: 'txt',
        fileSize: doc.fileSize,
        sourceType: 'paste',
        processingStatus: 'pending',
        jobId: job.id,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function getDocumentStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const documentId = Number(req.params.id);
    const db = getDb();

    const rows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id}`
    ).all();

    const doc = rows[0];
    if (!doc) {
      throw new NotFoundError('Document');
    }

    const jobs = queueService.getJobsByDocument(documentId);
    const latestJob = jobs[jobs.length - 1];

    res.json({
      success: true,
      data: {
        id: doc.id,
        originalName: doc.originalName,
        fileFormat: doc.fileFormat,
        uploadStatus: doc.uploadStatus,
        processingStatus: doc.processingStatus,
        isDeleted: doc.isDeleted,
        createdAt: doc.createdAt,
        job: latestJob
          ? { id: latestJob.id, status: latestJob.status, error: latestJob.error }
          : null,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function getDocumentAnalysis(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const documentId = Number(req.params.id);
    const db = getDb();

    const docRows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id}`
    ).all();

    if (!docRows[0]) {
      throw new NotFoundError('Document');
    }

    const analysisRows = db.select().from(analysisResults).where(
      sql`${analysisResults.documentId} = ${documentId}`
    ).all();

    const analysis = analysisRows[0];

    if (!analysis) {
      res.status(200).json({
        success: true,
        data: {
          status: docRows[0].processingStatus,
          analysis: null,
        },
      });
      return;
    }

    const clauseRows = db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysis.id}`).all();
    const riskRows = db.select().from(riskItems).where(sql`${riskItems.analysisId} = ${analysis.id}`).all();
    const deadlineRows = db.select().from(deadlines).where(sql`${deadlines.documentId} = ${documentId}`).all();

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
        clauses: clauseRows,
        riskItems: riskRows,
        deadlines: deadlineRows,
      },
    });
  } catch (err) {
    next(err);
  }
}

function safeJsonParse(value: string | null): unknown {
  if (!value) return [];
  try {
    return JSON.parse(value);
  } catch {
    return [];
  }
}
