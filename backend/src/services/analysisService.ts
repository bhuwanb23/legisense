import { getDb } from '../config/database';
import { documents, analysisResults, clauses, riskItems, deadlines } from '../models';
import { sql } from 'drizzle-orm';
import { readFile } from '../storage/fileStorage';
import { extractText } from './textExtractor';
import { analyzeDocument, type AiAnalysisResult } from './aiService';
import { persistNow } from '../config/database';

export async function analyzeDocumentPipeline(documentId: number, userId: number): Promise<void> {
  const db = getDb();

  const rows = db.select().from(documents).where(sql`${documents.id} = ${documentId}`).all();
  const doc = rows[0];

  if (!doc) {
    throw new Error(`Document ${documentId} not found`);
  }

  updateDocumentStatus(db, documentId, 'processing');

  try {
    const buffer = readFile(doc.storagePath);
    const rawText = await extractText(buffer, doc.fileFormat);

    updateDocumentRawText(db, documentId, rawText);

    const aiResult = await analyzeDocument(rawText);

    saveAnalysisResults(db, documentId, userId, aiResult);

    updateDocumentStatus(db, documentId, 'completed');
    persistNow();

    console.log(`Analysis complete for document ${documentId}`);
  } catch (err) {
    updateDocumentStatus(db, documentId, 'failed');
    persistNow();

    const message = err instanceof Error ? err.message : String(err);
    console.error(`Analysis failed for document ${documentId}:`, message);
    throw err;
  }
}

function updateDocumentStatus(db: any, documentId: number, status: string): void {
  db.run(sql`UPDATE ${documents} SET processing_status = ${status}, updated_at = datetime('now') WHERE id = ${documentId}`);
}

function updateDocumentRawText(db: any, documentId: number, rawText: string): void {
  db.run(sql`UPDATE ${documents} SET raw_text = ${rawText}, updated_at = datetime('now') WHERE id = ${documentId}`);
}

function saveAnalysisResults(
  db: any,
  documentId: number,
  userId: number,
  ai: AiAnalysisResult
): void {
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
    processingTime: 0,
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
