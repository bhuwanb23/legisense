import { Request, Response, NextFunction } from 'express';
import { getDb, persistNow } from '../config/database';
import { documents, analysisResults, clauses, riskItems, deadlines } from '../models';
import { sql } from 'drizzle-orm';
import { BadRequestError, NotFoundError } from '../utils/errors';
import { encryptText, isEncryptionConfigured } from '../services/encryptionService';
import { scrapeUrl, isValidUrl } from '../services/urlScraper';
import { analysisQueue } from '../queue';

function nowPlus24Hours(): string {
  return new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function specPayload(documentId: number) {
  const db = getDb();
  const analysis = (await db.select().from(analysisResults).where(sql`${analysisResults.documentId} = ${documentId}`))[0];
  const clauseRows = analysis
    ? await db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysis.id}`)
    : [];
  const riskRows = analysis
    ? await db.select().from(riskItems).where(sql`${riskItems.analysisId} = ${analysis.id}`)
    : [];
  const deadlineRows = await db.select().from(deadlines).where(sql`${deadlines.documentId} = ${documentId}`);
  let missing: unknown[] = [];
  try { missing = JSON.parse(analysis?.missingClauses || '[]'); } catch { missing = []; }

  return {
    documentId,
    document_type: analysis?.documentType,
    risk_score: analysis?.overallRiskScore,
    risk_level: analysis?.riskLevel,
    summary: analysis?.summary,
    clauses: clauseRows,
    risks: riskRows,
    missing_clauses: missing,
    deadlines: deadlineRows,
    processing_time: analysis?.processingTime,
  };
}

export async function publicAnalyze(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new BadRequestError('Unauthorized');
    const sourceType = String(req.body?.sourceType || req.body?.source_type || 'text').toLowerCase();
    const content = String(req.body?.content || req.body?.text || '').trim();
    const jurisdiction = String(req.body?.jurisdiction || '');
    const language = String(req.body?.language || 'en');
    const title = String(req.body?.title || `API analyze ${Date.now()}`);

    let text = content;
    let source: 'paste' | 'url' = 'paste';
    let sourceUrl: string | null = null;

    if (sourceType === 'url') {
      if (!isValidUrl(content)) throw new BadRequestError('A valid http:// or https:// URL is required');
      const scraped = await scrapeUrl(content);
      text = scraped.text;
      source = 'url';
      sourceUrl = content;
    } else if (sourceType === 'file' && req.body?.content) {
      try {
        text = Buffer.from(String(req.body.content), 'base64').toString('utf-8');
      } catch {
        throw new BadRequestError('Invalid base64 file content');
      }
    }

    if (!text || text.length < 50) throw new BadRequestError('content must be at least 50 characters');

    let storedText = text;
    let storedIv: string | null = null;
    if (isEncryptionConfigured()) {
      const enc = encryptText(text);
      storedText = enc.ciphertext;
      storedIv = enc.iv;
    }

    const parts = jurisdiction.split(/[,\-]/).map((s) => s.trim()).filter(Boolean);
    const countryCode = (parts[1] || parts[0] || 'IN').slice(0, 2).toUpperCase();
    const stateCode = (parts[0]?.length > 2 ? parts[0] : parts[0] || '').toUpperCase() || null;

    const db = getDb();
    await db.insert(documents).values({
      userId: req.user.id,
      originalName: title,
      storagePath: `api:${Date.now()}`,
      fileFormat: 'txt',
      fileSize: Buffer.byteLength(text, 'utf-8'),
      sourceType: source,
      sourceUrl,
      autoDeleteAt: nowPlus24Hours(),
      rawText: storedText,
      encryptionIv: storedIv,
      uploadStatus: 'uploaded',
      processingStatus: 'pending',
      countryCode,
      stateCode,
      detectedLanguage: language,
    });

    const idRows = (await db.execute(sql`SELECT id as id`)).rows as { id: number }[];
    const documentId = Number(idRows[0]?.id);
    const doc = (await db.select().from(documents).where(sql`${documents.id} = ${documentId}`))[0];
    if (!doc) throw new Error('Failed to create document');
    persistNow();

    const job = await analysisQueue.add('analyze', { documentId: doc.id, userId: req.user.id });

    const waitUntil = Date.now() + Number(process.env.V1_ANALYZE_WAIT_MS || 75_000);
    while (Date.now() < waitUntil) {
      const latest = (await db.select().from(documents).where(sql`${documents.id} = ${doc.id}`))[0];
      if (latest?.processingStatus === 'analyzed') {
        res.status(200).json({ success: true, data: specPayload(doc.id) });
        return;
      }
      if (latest?.processingStatus === 'failed') {
        res.status(202).json({
          success: true,
          data: {
            documentId: doc.id,
            jobId: job.id,
            status: 'failed',
            message: 'Analysis queued but the current attempt failed. Retry GET /api/v1/analyze/:documentId later.',
          },
        });
        return;
      }
      await sleep(1500);
    }

    const latest = (await db.select().from(documents).where(sql`${documents.id} = ${doc.id}`))[0];
    res.status(202).json({
      success: true,
      data: {
        documentId: doc.id,
        jobId: job.id,
        status: latest?.processingStatus || 'pending',
        message: 'Analysis queued. Poll GET /api/v1/analyze/:documentId',
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function getPublicAnalyze(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new BadRequestError('Unauthorized');
    const documentId = Number(req.params.documentId);
    const db = getDb();
    const doc = (await db.select().from(documents).where(
      sql`${documents.id} = ${documentId} AND ${documents.userId} = ${req.user.id} AND ${documents.isDeleted} = FALSE`
    ))[0];
    if (!doc) throw new NotFoundError('Document');

    if (doc.processingStatus === 'analyzed') {
      res.status(200).json({ success: true, data: specPayload(documentId) });
      return;
    }

    res.status(202).json({
      success: true,
      data: {
        documentId,
        status: doc.processingStatus,
        message: 'Analysis still running',
      },
    });
  } catch (err) {
    next(err);
  }
}
