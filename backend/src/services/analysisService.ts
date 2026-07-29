import { getDb, persistNow } from '../config/database';
import { documents, analysisResults, clauses, riskItems, deadlines, usageLogs } from '../models';
import { sql } from 'drizzle-orm';
import { readFile } from '../storage/fileStorage';
import { extractText } from './textExtractor';
import { callWithFallback, selectProviderForTokens } from './ai';
import { estimateTokens } from './ai/tokenManager';
import { ANALYSIS_SYSTEM_PROMPT, buildAnalysisUserPrompt, parseAiResponse } from '../prompts/analysisPrompt';
import { CLASSIFY_SYSTEM_PROMPT, ClassifyOutputSchema, buildClassifyUserPrompt, parseClassifyResponse, type ClassifyOutput } from '../prompts/classificationPrompt';
import { getPromptForType } from '../prompts/promptTemplates';
import { getTypeEntry } from '../data/documentTypes';
import { AnalysisOutputSchema, type AnalysisOutput } from '../schemas/analysisSchemas';
import { chunkText, estimateTotalRequestTokens, mergeAnalysisResults } from './chunkingService';
import { emitToUser } from './socketService';
import { createNotification } from './notificationService';
import { encryptText, decryptText, isEncryptionConfigured } from './encryptionService';

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

    const rawText = await resolveDocumentText(doc, documentId);

    emitToUser(doc.userId, 'analysis:progress', { documentId, progress: 12, stage: 'Classifying document type...' });

    const classification = await classifyDocument(rawText);

    const typeEntry = getTypeEntry(classification.type);
    const needsConfirmation = classification.confidence < 60;

    db.run(sql`UPDATE ${documents} SET
      detected_type = ${classification.type},
      detected_type_confidence = ${classification.confidence},
      needs_type_confirmation = ${needsConfirmation ? 1 : 0},
      updated_at = datetime('now')
      WHERE id = ${documentId}`);

    emitToUser(doc.userId, 'analysis:progress', {
      documentId,
      progress: 15,
      stage: `Detected: ${typeEntry.typeLabel} (${classification.confidence}% confidence)`,
    });

    if (needsConfirmation) {
      emitToUser(doc.userId, 'analysis:needs_confirmation', {
        documentId,
        detectedType: classification.type,
        typeLabel: typeEntry.typeLabel,
        confidence: classification.confidence,
      });
    }

    const selectedPrompt = getPromptForType(classification.type);

    emitToUser(doc.userId, 'analysis:progress', { documentId, progress: 18, stage: 'Estimating document size...' });

    const totalTokens = estimateTotalRequestTokens(selectedPrompt, rawText);

    let analysisResult: AnalysisOutput;
    let providerUsed = 'unknown';
    let modelUsed = 'unknown';
    let totalInputTokens = 0;
    let totalOutputTokens = 0;

    if (totalTokens > CHUNK_TOKEN_LIMIT) {
      emitToUser(doc.userId, 'analysis:progress', { documentId, progress: 20, stage: `Large document (${totalTokens.toLocaleString()} tokens). Splitting into chunks...` });
      const chunkResult = await analyzeInChunks(rawText, selectedPrompt, documentId, doc.userId);
      analysisResult = chunkResult.result;
      providerUsed = chunkResult.provider;
      modelUsed = chunkResult.model;
      totalInputTokens = chunkResult.inputTokens;
      totalOutputTokens = chunkResult.outputTokens;
    } else {
      emitToUser(doc.userId, 'analysis:progress', { documentId, progress: 25, stage: 'Analyzing document...' });
      const singleResult = await analyzeSingle(rawText, selectedPrompt);
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

    autoCreateDeadlines(documentId, doc.userId, analysisResult.criticalDates);

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

async function resolveDocumentText(doc: Record<string, unknown>, documentId: number): Promise<string> {
  const rawText = decryptDocumentText(doc as { rawText: string | null; encryptionIv: string | null });
  if (rawText && rawText.trim().length > 0) {
    return rawText;
  }

  const db = getDb();
  emitToUser((doc as { userId: number }).userId, 'analysis:progress', { documentId, progress: 8, stage: 'Extracting text from file...' });

  const buffer = await readFile((doc as { storagePath: string }).storagePath);
  const { text } = await extractText(buffer, (doc as { fileFormat: string }).fileFormat);

  let storedText = text;
  let storedIv: string | null = null;

  if (isEncryptionConfigured()) {
    const { ciphertext, iv } = encryptText(text);
    storedText = ciphertext;
    storedIv = iv;
  }

  if (storedIv) {
    db.run(sql`UPDATE ${documents} SET raw_text = ${storedText}, encryption_iv = ${storedIv}, updated_at = datetime('now') WHERE id = ${documentId}`);
  } else {
    db.run(sql`UPDATE ${documents} SET raw_text = ${storedText}, updated_at = datetime('now') WHERE id = ${documentId}`);
  }

  return text;
}

export async function classifyDocument(text: string): Promise<ClassifyOutput> {
  const { response } = await callWithFallback(
    {
      systemPrompt: CLASSIFY_SYSTEM_PROMPT,
      userPrompt: buildClassifyUserPrompt(text),
      temperature: 0.2,
    },
    { task: 'classification' },
  );

  const parsed = typeof response.text === 'string' ? parseClassifyResponse(response.text) : response.text;
  return ClassifyOutputSchema.parse(parsed);
}

async function analyzeSingle(
  text: string,
  systemPrompt: string,
): Promise<{ result: AnalysisOutput; provider: string; model: string; inputTokens: number; outputTokens: number }> {
  const estimatedTokens = estimateTotalRequestTokens(systemPrompt, text);
  const provider = selectProviderForTokens(estimatedTokens);

  let lastError: string | null = null;

  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    try {
      const prompt = attempt > 0
        ? systemPrompt + `\n\nNOTE: Your previous response failed validation (${lastError}). Ensure the JSON is valid and matches the required structure exactly. No extra fields. All fields must be present.`
        : systemPrompt;

      const userPrompt = buildAnalysisUserPrompt(text);

      const { response, providerUsed } = await callWithFallback(
        { systemPrompt: prompt, userPrompt, temperature: 0.3 },
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
  systemPrompt: string,
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

    const singleResult = await analyzeSingle(text, systemPrompt);
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

export function calculateOverallRiskScore(clauses: AnalysisOutput['clauses']): { overallScore: number; riskLevel: 'low' | 'medium' | 'high' } {
  if (clauses.length === 0) return { overallScore: 0, riskLevel: 'low' as const };

  let weightedSum = 0;
  let totalWeight = 0;
  let hasCritical = false;

  for (const c of clauses) {
    const score = c.riskScore;
    if (score >= 90) hasCritical = true;

    const weight = score >= 67 ? 2.0 : score >= 34 ? 1.0 : 0.5;
    weightedSum += score * weight;
    totalWeight += weight;
  }

  let overall = Math.round(weightedSum / totalWeight);
  if (hasCritical) overall = Math.max(overall, 60);

  const riskLevel: 'low' | 'medium' | 'high' = overall <= 33 ? 'low' : overall <= 66 ? 'medium' : 'high';
  return { overallScore: overall, riskLevel };
}

function saveAnalysisResults(
  documentId: number,
  userId: number,
  ai: AnalysisOutput,
  processingTime: number,
  modelUsed?: string,
): void {
  const db = getDb();

  const computed = calculateOverallRiskScore(ai.clauses);
  ai.overallRiskScore = computed.overallScore;
  ai.riskLevel = computed.riskLevel;

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
    breachScenarios: JSON.stringify(ai.breachScenarios),
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
        readingLevel: clause.readingLevel,
        keyLegalTerms: JSON.stringify(clause.keyLegalTerms),
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

    generateRiskItemsFromClauses(analysisId);

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

function calculateUrgencyLevel(dateStr: string): string {
  if (!dateStr || dateStr.length < 10) return 'medium';

  const parsed = new Date(dateStr);
  if (isNaN(parsed.getTime())) return 'medium';

  const now = new Date();
  const diffMs = parsed.getTime() - now.getTime();
  const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return 'overdue';
  if (diffDays <= 7) return 'critical';
  if (diffDays <= 30) return 'high';
  if (diffDays <= 90) return 'medium';
  return 'low';
}

function autoCreateDeadlines(documentId: number, userId: number, criticalDates: AnalysisOutput['criticalDates']): void {
  const db = getDb();

  for (const cd of criticalDates) {
    const existing = db.select().from(deadlines).where(
      sql`${deadlines.documentId} = ${documentId} AND ${deadlines.title} = ${cd.label}`
    ).all();

    const urgencyLevel = calculateUrgencyLevel(cd.date);

    if (existing.length > 0) {
      db.run(sql`UPDATE ${deadlines} SET
        description = ${cd.importance || cd.label},
        due_date = ${cd.date},
        urgency_level = ${urgencyLevel}
        WHERE id = ${existing[0].id}`);
    } else {
      db.insert(deadlines).values({
        documentId,
        userId,
        title: cd.label,
        description: cd.importance || cd.label,
        dueDate: cd.date,
        urgencyLevel,
        recurrence: 'one-time',
      }).run();
    }
  }
}

function severityFromScore(score: number): string {
  if (score >= 90) return 'critical';
  if (score >= 67) return 'high';
  if (score >= 34) return 'medium';
  return 'low';
}

function generateRiskItemsFromClauses(analysisId: number): void {
  const db = getDb();

  const clauseRows = db.select().from(clauses).where(
    sql`${clauses.analysisId} = ${analysisId}`
  ).all();

  const grouped: Record<string, typeof clauseRows> = {};
  for (const c of clauseRows) {
    const cat = c.riskCategory || 'other';
    if (!grouped[cat]) grouped[cat] = [];
    grouped[cat].push(c);
  }

  for (const [category, catClauses] of Object.entries(grouped)) {
    const maxRiskClause = catClauses.reduce((best, c) =>
      (c.riskScore ?? 0) > (best.riskScore ?? 0) ? c : best
    , catClauses[0]);

    const score = maxRiskClause.riskScore ?? 0;
    const severity = severityFromScore(score);
    const label = category.charAt(0).toUpperCase() + category.slice(1).replace(/_/g, ' ');

    db.insert(riskItems).values({
      analysisId,
      clauseId: maxRiskClause.id,
      riskType: category,
      title: `${label} Risk — ${catClauses.length} clause${catClauses.length > 1 ? 's' : ''} found`,
      description: maxRiskClause.riskReason || maxRiskClause.plainEnglishText || `Clauses categorized as ${label}.`,
      severity,
      severityScore: score,
      recommendation: maxRiskClause.counterSuggestion || 'Review this clause for potential risk mitigation.',
      legalReference: '',
    }).run();
  }
}
