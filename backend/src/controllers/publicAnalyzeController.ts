import { Request, Response, NextFunction } from 'express';
import { getDb, persistNow } from '../config/database';
import { documents, analysisResults, clauses, riskItems, deadlines } from '../models';
import { sql } from 'drizzle-orm';
import { BadRequestError } from '../utils/errors';
import { encryptText, isEncryptionConfigured } from '../services/encryptionService';
import { scrapeUrl, isValidUrl } from '../services/urlScraper';
import { processDocumentSync } from '../services/analysisService';

function nowPlus24Hours(): string {
  return new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
}

export async function publicAnalyze(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) throw new BadRequestError('Unauthorized');
    const sourceType = String(req.body?.sourceType || req.body?.source_type || 'text').toLowerCase();
    const content = String(req.body?.content || req.body?.text || '').trim();
    const jurisdiction = String(req.body?.jurisdiction || '');
    const language = String(req.body?.language || 'en');
    const title = String(req.body?.title || 'API analyze');

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
    db.insert(documents).values({
      userId: req.user.id,
      originalName: title,
      storagePath: '',
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
    }).run();

    const doc = db.select().from(documents).where(
      sql`${documents.originalName} = ${title} AND ${documents.userId} = ${req.user.id}`
    ).all().pop();
    if (!doc) throw new Error('Failed to create document');
    persistNow();

    await processDocumentSync(doc.id);

    const analysis = db.select().from(analysisResults).where(sql`${analysisResults.documentId} = ${doc.id}`).all()[0];
    const clauseRows = analysis
      ? db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysis.id}`).all()
      : [];
    const riskRows = analysis
      ? db.select().from(riskItems).where(sql`${riskItems.analysisId} = ${analysis.id}`).all()
      : [];
    const deadlineRows = db.select().from(deadlines).where(sql`${deadlines.documentId} = ${doc.id}`).all();

    let missing: unknown[] = [];
    try { missing = JSON.parse(analysis?.missingClauses || '[]'); } catch { missing = []; }

    res.status(200).json({
      success: true,
      data: {
        documentId: doc.id,
        document_type: analysis?.documentType,
        risk_score: analysis?.overallRiskScore,
        risk_level: analysis?.riskLevel,
        summary: analysis?.summary,
        clauses: clauseRows,
        risks: riskRows,
        missing_clauses: missing,
        deadlines: deadlineRows,
        processing_time: analysis?.processingTime,
      },
    });
  } catch (err) {
    next(err);
  }
}
