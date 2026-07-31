import { Request, Response, NextFunction } from 'express';
import { getDb } from '../config/database';
import { documents, analysisResults, clauses, riskItems, deadlines, users } from '../models';
import { sql } from 'drizzle-orm';
import { saveFile, deleteFile } from '../storage/fileStorage';
import { NotFoundError, BadRequestError } from '../utils/errors';
import { persistNow } from '../config/database';
import { encryptText, isEncryptionConfigured } from '../services/encryptionService';
import { scrapeUrl, isValidUrl } from '../services/urlScraper';
import { parseUserJurisdiction } from '../services/jurisdictionCheckService';
import { processDocumentSync } from '../services/analysisService';

function nowPlus24Hours(): string {
  return new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
}

function resolveJurisdictionFromRequest(req: Request): { countryCode: string | null; stateCode: string | null } {
  let countryCode = (req.body?.country_code || req.body?.countryCode || null) as string | null;
  let stateCode = (req.body?.state_code || req.body?.stateCode || null) as string | null;

  if (!countryCode && req.user) {
    const db = getDb();
    const userRows = db.select().from(users).where(sql`${users.id} = ${req.user.id}`).all();
    const parsed = parseUserJurisdiction(userRows[0]?.defaultJurisdiction);
    countryCode = parsed.countryCode;
    stateCode = stateCode || parsed.stateCode;
  }

  return {
    countryCode: countryCode ? String(countryCode).toUpperCase() : null,
    stateCode: stateCode ? String(stateCode).toUpperCase() : null,
  };
}

export async function uploadDocument(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const sourceType = req.body.sourceType || req.body.source_type || 'file';

    switch (sourceType) {
      case 'file':
        return handleFileUpload(req, res, next);
      case 'scan':
        return handleScanUpload(req, res, next);
      case 'paste':
        return handlePasteUpload(req, res, next);
      case 'url':
        return handleUrlUpload(req, res, next);
      default:
        throw new BadRequestError(`Invalid source_type "${sourceType}". Use: file, scan, paste, or url`);
    }
  } catch (err) {
    next(err);
  }
}

async function handleFileUpload(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) return;
    if (!req.file) {
      res.status(400).json({ success: false, error: { message: 'No file uploaded', code: 'NO_FILE', statusCode: 400 } });
      return;
    }

    const { originalname, buffer } = req.file;
    const format = originalname.split('.').pop()?.toLowerCase() || 'unknown';
    const storagePath = await saveFile(buffer, originalname, format);
    const db = getDb();
    const jur = resolveJurisdictionFromRequest(req);

    db.insert(documents).values({
      userId: req.user.id,
      originalName: originalname,
      storagePath,
      fileFormat: format,
      fileSize: buffer.length,
      sourceType: 'file',
      uploadStatus: 'uploaded',
      processingStatus: 'pending',
      autoDeleteAt: nowPlus24Hours(),
      countryCode: jur.countryCode,
      stateCode: jur.stateCode,
    }).run();

    const doc = db.select().from(documents).where(sql`${documents.storagePath} = ${storagePath}`).all()[0];
    if (!doc) throw new Error('Failed to create document record');
    persistNow();

    res.status(202).json({
      success: true,
      data: {
        documentId: doc.id,
        originalName: doc.originalName,
        fileFormat: doc.fileFormat,
        fileSize: doc.fileSize,
        uploadStatus: 'uploaded',
        processingStatus: 'pending',
      },
    });
  } catch (err) { next(err); }
}

async function handleScanUpload(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) return;
    if (!req.file) {
      res.status(400).json({ success: false, error: { message: 'No image uploaded', code: 'NO_FILE', statusCode: 400 } });
      return;
    }

    const IMAGE_EXTS = ['.png', '.jpg', '.jpeg', '.heic', '.heif'];
    const ext = '.' + (req.file.originalname.split('.').pop()?.toLowerCase() || '');
    if (!IMAGE_EXTS.includes(ext)) {
      res.status(400).json({ success: false, error: { message: `Scan source_type requires an image file (${IMAGE_EXTS.join(', ')})`, code: 'INVALID_FILE_TYPE', statusCode: 400 } });
      return;
    }

    const { originalname, buffer } = req.file;
    const format = originalname.split('.').pop()?.toLowerCase() || 'unknown';
    const storagePath = await saveFile(buffer, originalname, format);
    const db = getDb();
    const jur = resolveJurisdictionFromRequest(req);

    db.insert(documents).values({
      userId: req.user.id,
      originalName: originalname,
      storagePath,
      fileFormat: format,
      fileSize: buffer.length,
      sourceType: 'scan',
      uploadStatus: 'uploaded',
      processingStatus: 'pending',
      autoDeleteAt: nowPlus24Hours(),
      countryCode: jur.countryCode,
      stateCode: jur.stateCode,
    }).run();

    const doc = db.select().from(documents).where(sql`${documents.storagePath} = ${storagePath}`).all()[0];
    if (!doc) throw new Error('Failed to create document record');
    persistNow();

    res.status(202).json({
      success: true,
      data: {
        documentId: doc.id,
        originalName: doc.originalName,
        fileFormat: doc.fileFormat,
        fileSize: doc.fileSize,
        uploadStatus: 'uploaded',
        processingStatus: 'pending',
      },
    });
  } catch (err) { next(err); }
}

async function handlePasteUpload(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) return;

    const { text, title } = req.body;
    const docTitle = title || 'Pasted Text';

    if (!text || text.trim().length < 50) {
      res.status(400).json({ success: false, error: { message: 'Pasted text must be at least 50 characters', code: 'TEXT_TOO_SHORT', statusCode: 400 } });
      return;
    }

    let storedText = text;
    let storedIv: string | null = null;
    if (isEncryptionConfigured()) {
      const { ciphertext, iv } = encryptText(text);
      storedText = ciphertext;
      storedIv = iv;
    }

    const db = getDb();
    const jur = resolveJurisdictionFromRequest(req);

    db.insert(documents).values({
      userId: req.user.id,
      originalName: docTitle,
      storagePath: '',
      fileFormat: 'txt',
      fileSize: Buffer.byteLength(text, 'utf-8'),
      sourceType: 'paste',
      autoDeleteAt: nowPlus24Hours(),
      rawText: storedText,
      encryptionIv: storedIv,
      uploadStatus: 'uploaded',
      processingStatus: 'pending',
      countryCode: jur.countryCode,
      stateCode: jur.stateCode,
    }).run();

    const doc = db.select().from(documents).where(sql`${documents.originalName} = ${docTitle} AND ${documents.userId} = ${req.user.id}`).all().pop();
    if (!doc) throw new Error('Failed to create document record');
    persistNow();

    res.status(202).json({
      success: true,
      data: {
        documentId: doc.id,
        originalName: doc.originalName,
        fileFormat: 'txt',
        fileSize: doc.fileSize,
        sourceType: 'paste',
        processingStatus: 'pending',
      },
    });
  } catch (err) { next(err); }
}

async function handleUrlUpload(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) return;

    const { url, title } = req.body;

    if (!url || !isValidUrl(url)) {
      res.status(400).json({ success: false, error: { message: 'A valid http:// or https:// URL is required', code: 'INVALID_URL', statusCode: 400 } });
      return;
    }

    const scraped = await scrapeUrl(url);
    const docTitle = title || scraped.title || 'Imported URL';

    let storedText = scraped.text;
    let storedIv: string | null = null;
    if (isEncryptionConfigured()) {
      const { ciphertext, iv } = encryptText(scraped.text);
      storedText = ciphertext;
      storedIv = iv;
    }

    const db = getDb();
    const jur = resolveJurisdictionFromRequest(req);

    db.insert(documents).values({
      userId: req.user.id,
      originalName: docTitle,
      storagePath: '',
      fileFormat: 'url',
      fileSize: Buffer.byteLength(scraped.text, 'utf-8'),
      sourceType: 'url',
      sourceUrl: url,
      autoDeleteAt: nowPlus24Hours(),
      rawText: storedText,
      encryptionIv: storedIv,
      uploadStatus: 'uploaded',
      processingStatus: 'pending',
      countryCode: jur.countryCode,
      stateCode: jur.stateCode,
    }).run();

    const doc = db.select().from(documents).where(sql`${documents.sourceUrl} = ${url} AND ${documents.userId} = ${req.user.id}`).all().pop();
    if (!doc) throw new Error('Failed to create document record');
    persistNow();

    res.status(202).json({
      success: true,
      data: {
        documentId: doc.id,
        originalName: doc.originalName,
        fileFormat: 'url',
        fileSize: doc.fileSize,
        sourceType: 'url',
        sourceUrl: url,
        processingStatus: 'pending',
      },
    });
  } catch (err) { next(err); }
}

export async function pasteText(req: Request, res: Response, next: NextFunction): Promise<void> {
  return handlePasteUpload(req, res, next);
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
        countryCode: doc.countryCode,
        stateCode: doc.stateCode,
        detectedLanguage: doc.detectedLanguage,
        uploadStatus: doc.uploadStatus,
        processingStatus: doc.processingStatus,
        pageCount: doc.pageCount,
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

    const doc = rows[0];
    if (!doc) {
      throw new NotFoundError('Document');
    }

    if (doc.storagePath) {
      await deleteFile(doc.storagePath);
    }

    db.run(
      sql`UPDATE ${documents} SET is_deleted = 1, raw_text = NULL, encryption_iv = NULL, updated_at = datetime('now') WHERE id = ${documentId}`
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
      },
    });
  } catch (err) {
    next(err);
  }
}

/** Blocking extract → LLM → save. One REST call; no status polls / sockets. */
export async function processDocument(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const documentId = Number(req.params.id);
    if (!documentId) throw new BadRequestError('Invalid document ID');

    const db = getDb();
    const rows = db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = 0`
    ).all();

    if (!rows[0]) throw new NotFoundError('Document');

    req.setTimeout?.(600_000);
    res.setTimeout?.(600_000);

    const force =
      req.query.force === '1' ||
      req.query.force === 'true' ||
      req.body?.force === true ||
      req.body?.force === '1';

    const bundle = await processDocumentSync(documentId, { force });
    res.json({ success: true, data: bundle });
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
        status: docRows[0].processingStatus,
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

export async function translateDocument(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED', statusCode: 401 } });
      return;
    }

    const documentId = Number(req.params.id);
    const targetLanguage = String(req.body?.targetLanguage || req.body?.target_language || '').toLowerCase();
    if (!targetLanguage) {
      throw new BadRequestError('targetLanguage is required');
    }

    const { translateAnalysisResults } = await import('../services/translationService');
    const snapshot = await translateAnalysisResults(documentId, req.user.id, targetLanguage);

    res.json({
      success: true,
      data: snapshot,
    });
  } catch (err) {
    next(err);
  }
}
