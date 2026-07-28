import { getDb } from '../config/database';
import { documents, analysisResults, clauses, riskItems, deadlines, notifications, usageLogs } from '../models';
import { sql } from 'drizzle-orm';
import { readFile } from '../storage/fileStorage';
import { extractText } from './textExtractor';
import { analyzeDocument, type AiAnalysisResult } from './aiService';
import { persistNow } from '../config/database';
import { emitToUser } from './socketService';

export async function analyzeDocumentPipeline(documentId: number, userId: number): Promise<void> {
  const db = getDb();
  const startTime = Date.now();

  const rows = db.select().from(documents).where(sql`${documents.id} = ${documentId}`).all();
  const doc = rows[0];

  if (!doc) {
    throw new Error(`Document ${documentId} not found`);
  }

  updateDocumentStatus(documentId, 'processing');

  try {
    const buffer = readFile(doc.storagePath);
    const { text: rawText } = await extractText(buffer, doc.fileFormat);

    updateDocumentRawText(documentId, rawText);

    const aiResult = await analyzeDocument(rawText);

    const processingTime = (Date.now() - startTime) / 1000;

    db.insert(usageLogs).values({
      userId: doc.userId,
      action: 'analysis:complete',
      documentId,
      processingTime,
    }).run();

    saveAnalysisResults(documentId, doc.userId, aiResult, processingTime);

    updateDocumentStatus(documentId, 'completed');

    createNotification(documentId, doc.userId, 'analysis_complete', 'Analysis Complete', `Analysis of "${doc.originalName}" is complete.`);

    emitToUser(doc.userId, 'analysis:complete', { documentId });

    persistNow();
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);

    db.insert(usageLogs).values({
      userId: doc.userId,
      action: 'analysis:failed',
      documentId,
      processingTime: (Date.now() - startTime) / 1000,
    }).run();

    updateDocumentStatus(documentId, 'failed');

    createNotification(documentId, doc.userId, 'analysis_failed', 'Analysis Failed', `Analysis of "${doc.originalName}" failed: ${message}`);

    emitToUser(doc.userId, 'analysis:failed', { documentId, error: message });

    persistNow();

    console.error(`Analysis failed for document ${documentId}:`, message);
    throw err;
  }
}

function updateDocumentStatus(documentId: number, status: string): void {
  const db = getDb();
  db.run(sql`UPDATE ${documents} SET processing_status = ${status}, updated_at = datetime('now') WHERE id = ${documentId}`);
}

function updateDocumentRawText(documentId: number, rawText: string): void {
  const db = getDb();
  db.run(sql`UPDATE ${documents} SET raw_text = ${rawText}, updated_at = datetime('now') WHERE id = ${documentId}`);
}

function createNotification(documentId: number, userId: number, type: string, title: string, body: string): void {
  const db = getDb();
  db.insert(notifications).values({
    userId,
    type,
    title,
    body,
    documentId,
    isRead: false,
  }).run();
}

function saveAnalysisResults(
  documentId: number,
  userId: number,
  ai: AiAnalysisResult,
  processingTime: number
): void {
  const db = getDb();

  db.insert(analysisResults).values({
    documentId,
    userId,
    documentType: ai.documentType,
    detectedTypeConfidence: ai.detectedTypeConfidence,
    overallRiskScore: ai.overallRiskScore,
    riskLevel: ai.riskLevel,
    fairnessScore: ai.fairnessScore,
    favorsParty: ai.favorsParty,
    summary: ai.summary,
    keyParties: JSON.stringify(ai.keyParties),
    criticalDates: JSON.stringify(ai.criticalDates),
    keyObligations: JSON.stringify(ai.keyObligations),
    missingClauses: JSON.stringify(ai.missingClauses),
    jurisdictionFlags: JSON.stringify([]),
    processingTime,
    aiModelUsed: 'gemini-1.5-flash',
  }).run();

  const analysisRows = db.select().from(analysisResults).where(sql`${analysisResults.documentId} = ${documentId}`).all();
  const analysisId = analysisRows[0]?.id;

  if (analysisId) {
    for (const clause of ai.clauses) {
      db.insert(clauses).values({
        documentId,
        analysisId,
        clauseNumber: clause.clauseNumber,
        clauseTitle: clause.clauseTitle,
        originalText: clause.originalText,
        plainEnglishText: clause.plainEnglishText,
        riskLevel: clause.riskLevel,
        riskScore: clause.riskScore,
        riskReason: clause.riskReason,
        riskCategory: clause.riskCategory,
        counterSuggestion: clause.counterSuggestion,
      }).run();
    }

    for (const risk of ai.riskItems) {
      db.insert(riskItems).values({
        analysisId,
        riskType: risk.riskType,
        title: risk.title,
        description: risk.description,
        severity: risk.severity,
        severityScore: risk.severityScore,
        recommendation: risk.recommendation,
        legalReference: risk.legalReference,
      }).run();
    }

    for (const deadline of ai.deadlines) {
      db.insert(deadlines).values({
        documentId,
        userId,
        title: deadline.title,
        description: deadline.description,
        dueDate: deadline.dueDate,
        recurrence: deadline.recurrence,
      }).run();
    }
  }
}
