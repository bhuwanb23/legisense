import { getDb, persistNow } from '../config/database';
import { documents, analysisResults, clauses, riskItems, deadlines, usageLogs } from '../models';
import { sql } from 'drizzle-orm';
import { callWithFallback, selectProviderForTokens } from './ai';
import { estimateTokens } from './ai/tokenManager';
import { ANALYSIS_SYSTEM_PROMPT, buildAnalysisUserPrompt, parseAiResponse } from '../prompts/analysisPrompt';
import { AnalysisOutputSchema, type AnalysisOutput } from '../schemas/analysisSchemas';
import { chunkText, estimateTotalRequestTokens, mergeAnalysisResults } from './chunkingService';
import { emitToUser } from './socketService';
import { createNotification } from './notificationService';
import { decryptText, isEncryptionConfigured } from './encryptionService';

const MAX_RETRIES = 3;
const CHUNK_TOKEN_LIMIT = 500_000;

export async function analyzeDocumentPipeline(documentId: number, userId: number): Promise<void> {
  const db = getDb();
  const startTime = Date.now();

  const rows = db.select().from(documents).where(sql`${documents.id} = ${documentId}`).all();
  const doc = rows[0];

  if (!doc) {
    throw new Error(`Document ${documentId} not found`);
  }

  updateDocumentStatus(documentId, 'processing');
  emitToUser(doc.userId, 'analysis:started', { documentId });

  try {
    emitToUser(doc.userId, 'analysis:progress', { documentId, progress: 5, stage: 'Reading document text...' });

    const rawText = decryptDocumentText(doc);
    if (!rawText || rawText.trim().length === 0) {
      throw new Error('Document has no extractable text. Try re-uploading or pasting the content manually.');
    }

    emitToUser(doc.userId, 'analysis:progress', { documentId, progress: 15, stage: 'Estimating document size...' });

    const totalTokens = estimateTotalRequestTokens(ANALYSIS_SYSTEM_PROMPT, rawText);

    let analysisResult: AnalysisOutput;
    let providerUsed = 'unknown';
    let modelUsed = 'unknown';
    let totalInputTokens = 0;
    let totalOutputTokens = 0;

    if (totalTokens > CHUNK_TOKEN_LIMIT) {
      emitToUser(doc.userId, 'analysis:progress', { documentId, progress: 20, stage: `Large document (${totalTokens.toLocaleString()} tokens). Splitting into chunks...` });
      const chunkResult = await analyzeInChunks(rawText, documentId, doc.userId);
      analysisResult = chunkResult.result;
      providerUsed = chunkResult.provider;
      modelUsed = chunkResult.model;
      totalInputTokens = chunkResult.inputTokens;
      totalOutputTokens = chunkResult.outputTokens;
    } else {
      emitToUser(doc.userId, 'analysis:progress', { documentId, progress: 25, stage: 'Analyzing document...' });
      const singleResult = await analyzeSingle(rawText);
      analysisResult = singleResult.result;
      providerUsed = singleResult.provider;
      modelUsed = singleResult.model;
      totalInputTokens = singleResult.inputTokens;
      totalOutputTokens = singleResult.outputTokens;
    }

    emitToUser(doc.userId, 'analysis:progress', { documentId, progress: 95, stage: 'Saving results...' });

    const totalTime = (Date.now() - startTime) / 1000;

    db.insert(usageLogs).values({
      userId: doc.userId,
      action: 'analysis:completed',
      documentId,
      tokensConsumed: totalInputTokens + totalOutputTokens,
      processingTime: totalTime,
      provider: providerUsed,
      model: modelUsed,
      inputTokens: totalInputTokens,
      outputTokens: totalOutputTokens,
    }).run();

    saveAnalysisResults(documentId, doc.userId, analysisResult, totalTime, modelUsed);

    updateDocumentStatus(documentId, 'analyzed');

    createNotification(doc.userId, 'analysis_complete', 'Analysis Complete', `Analysis of "${doc.originalName}" is complete.`, documentId);

    emitToUser(doc.userId, 'analysis:completed', { documentId });

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

    createNotification(doc.userId, 'analysis_failed', 'Analysis Failed', `Analysis of "${doc.originalName}" failed: ${message}`, documentId);

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

function decryptDocumentText(doc: { rawText: string | null; encryptionIv: string | null }): string | null {
  if (!doc.rawText) return null;
  if (!doc.encryptionIv || !isEncryptionConfigured()) return doc.rawText;
  return decryptText(doc.rawText, doc.encryptionIv);
}

async function analyzeSingle(
  text: string,
): Promise<{ result: AnalysisOutput; provider: string; model: string; inputTokens: number; outputTokens: number }> {
  const estimatedTokens = estimateTotalRequestTokens(ANALYSIS_SYSTEM_PROMPT, text);
  const provider = selectProviderForTokens(estimatedTokens);

  let lastError: string | null = null;

  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    try {
      const systemPrompt = attempt > 0
        ? ANALYSIS_SYSTEM_PROMPT + `\n\nNOTE: Your previous response failed validation (${lastError}). Ensure the JSON is valid and matches the required structure exactly. No extra fields. All fields must be present.`
        : ANALYSIS_SYSTEM_PROMPT;

      const userPrompt = buildAnalysisUserPrompt(text);

      const { response, providerUsed } = await callWithFallback(
        { systemPrompt, userPrompt, temperature: 0.3 },
        { task: 'analysis' },
      );

      const parsed = typeof response.text === 'string' ? parseAiResponse(response.text) : response.text;

      const validated = AnalysisOutputSchema.parse(parsed);

      return {
        result: validated,
        provider: providerUsed,
        model: response.model,
        inputTokens: response.usage.inputTokens,
        outputTokens: response.usage.outputTokens,
      };
    } catch (err) {
      lastError = err instanceof Error ? err.message : String(err);
      if (attempt === MAX_RETRIES - 1) {
        throw new Error(`AI analysis failed after ${MAX_RETRIES} attempts: ${lastError}`);
      }
    }
  }

  throw new Error('AI analysis failed: unexpected error');
}

async function analyzeInChunks(
  fullText: string,
  documentId: number,
  userId: number,
): Promise<{ result: AnalysisOutput; provider: string; model: string; inputTokens: number; outputTokens: number }> {
  const chunks = chunkText(fullText);
  const chunkResults: AnalysisOutput[] = [];
  let lastProvider = '';
  let lastModel = '';
  let totalInputTokens = 0;
  let totalOutputTokens = 0;

  const chunkRange = 70 / chunks.length;
  let currentProgress = 25;

  for (let i = 0; i < chunks.length; i++) {
    const chunk = chunks[i];
    const progress = currentProgress + Math.round(chunkRange * (i + 1));

    emitToUser(userId, 'analysis:progress', {
      documentId,
      progress: Math.min(progress, 90),
      stage: `Analyzing part ${i + 1} of ${chunks.length}...`,
    });

    const text = `[This is part ${i + 1} of ${chunks.length} of a legal document. Analyze this portion and return the full JSON structure with all findings from this section.]\n\n${chunk.text}`;

    const singleResult = await analyzeSingle(text);
    chunkResults.push(singleResult.result);
    totalInputTokens += singleResult.inputTokens;
    totalOutputTokens += singleResult.outputTokens;
    lastProvider = singleResult.provider || lastProvider;
    lastModel = singleResult.model || lastModel;
  }

  return {
    result: mergeAnalysisResults(chunkResults),
    provider: lastProvider,
    model: lastModel,
    inputTokens: totalInputTokens,
    outputTokens: totalOutputTokens,
  };
}

function saveAnalysisResults(
  documentId: number,
  userId: number,
  ai: AnalysisOutput,
  processingTime: number,
  modelUsed?: string,
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
    aiModelUsed: modelUsed || 'unknown',
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
