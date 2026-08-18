import { getDb, persistNow } from '../config/database';
import { documents, analysisResults, clauses, riskItems, usageLogs, users, deadlines } from '../models';
import { sql } from 'drizzle-orm';
import { readFile } from '../storage/fileStorage';
import { extractDocumentText, extractFormatFromPath } from './documentExtractService';
import { callWithFallback, selectProviderForTokens } from './ai';
import { buildAnalysisUserPrompt, parseAiResponse, appendLanguageInstructions } from '../prompts/analysisPrompt';
import { CLASSIFY_SYSTEM_PROMPT, ClassifyOutputSchema, buildClassifyUserPrompt, parseClassifyResponse, type ClassifyOutput } from '../prompts/classificationPrompt';
import { getPromptForType } from '../prompts/promptTemplates';
import { normalizeTypeKey } from '../data/documentTypes';
import { AnalysisOutputSchema, type AnalysisOutput } from '../schemas/analysisSchemas';
import { chunkText, estimateTotalRequestTokens, mergeAnalysisResults } from './chunkingService';
import { createNotification } from './notificationService';
import { encryptText, decryptText, isEncryptionConfigured } from './encryptionService';
import { detectLanguage, toIso6391 } from './languageDetectionService';
import { runJurisdictionCheck } from './jurisdictionCheckService';
import { runConflictDetection } from './conflictDetectionService';
import { runRiskPatternScan } from './riskPatternService';
import { buildDeadlineInputsFromAnalysis, saveDeadlinesForDocument } from './deadlineService';
import { counterClausesQueue } from '../queue';
import {
  enrichAnalysisOutput,
  looksLikeNonLegalDocument,
  shouldPromoteClauseToRisk,
} from './analysisCleanup';

/** Initial attempt + one repair prompt for tiny local models. */
const MAX_RETRIES = 2;
const CHUNK_TOKEN_LIMIT = 500_000;
const ANALYSIS_MAX_CHARS = Number(process.env.ANALYSIS_MAX_CHARS || 8000);

function counterClausesEnabled(): boolean {
  const v = (process.env.COUNTER_CLAUSES_ENABLED || 'false').toLowerCase();
  return v === '1' || v === 'true' || v === 'on';
}

function truncateForLlm(text: string): string {
  if (text.length <= ANALYSIS_MAX_CHARS) return text;
  return `${text.slice(0, ANALYSIS_MAX_CHARS)}\n\n[Document truncated for local model context…]`;
}

export async function analyzeDocumentPipeline(documentId: number, _userId: number): Promise<void> {
  await processDocumentSync(documentId);
}

/**
 * Single blocking pipeline: extract text → one LLM analysis → save.
 * Pass force=true to re-run even if already analyzed.
 */
export async function processDocumentSync(
  documentId: number,
  options?: { force?: boolean },
): Promise<{
  status: string;
  analysis: Record<string, unknown> | null;
  clauses: unknown[];
  riskItems: unknown[];
  deadlines: unknown[];
}> {
  const db = getDb();
  const startTime = Date.now();

  const rows = db.select().from(documents).where(sql`${documents.id} = ${documentId}`).all();
  const doc = rows[0];
  if (!doc) throw new Error(`Document ${documentId} not found`);

  // Already analyzed — return existing bundle unless force refresh
  const existing = db.select().from(analysisResults).where(sql`${analysisResults.documentId} = ${documentId}`).all();
  if (!options?.force && existing[0] && doc.processingStatus === 'analyzed') {
    return getAnalysisBundleForDocument(documentId);
  }

  updateDocumentStatus(documentId, 'processing');

  try {
    const rawText = await resolveDocumentText(doc as unknown as Record<string, unknown>, documentId);
    const llmText = truncateForLlm(rawText);

    const userRows = db.select().from(users).where(sql`${users.id} = ${doc.userId}`).all();
    const preferredLanguage = toIso6391(userRows[0]?.preferredLanguage || 'en');
    const detected = detectLanguage(rawText);
    const detectedLang = detected.language;

    db.run(sql`UPDATE ${documents} SET
      detected_language = ${detectedLang},
      updated_at = datetime('now')
      WHERE id = ${documentId}`);

    // One LLM call — document type comes from the analysis JSON itself.
    // A template type hint (chosen at upload) steers the prompt when present.
    const hintKey = normalizeTypeKey(doc.detectedType);
    const selectedPrompt = appendLanguageInstructions(
      getPromptForType(hintKey === 'unknown' ? 'unknown' : hintKey),
      detectedLang,
      preferredLanguage,
    );

    console.log(`[process] doc=${documentId} chars=${llmText.length} lang=${detectedLang} → LLM`);

    let analysisResult: AnalysisOutput;
    let providerUsed: string;
    let modelUsed: string;
    let totalInputTokens: number;
    let totalOutputTokens: number;

    if (looksLikeNonLegalDocument(rawText)) {
      console.log(`[process] doc=${documentId} treated as non-contract (skip LLM)`);
      analysisResult = enrichAnalysisOutput(
        {
          documentType: 'Other',
          detectedTypeConfidence: 85,
          overallRiskScore: 0,
          riskLevel: 'low',
          fairnessScore: 50,
          favorsParty: 'Balanced',
          summary: 'Placeholder',
          keyParties: [],
          criticalDates: [],
          keyObligations: [],
          missingClauses: [],
          clauses: [],
          riskItems: [],
          deadlines: [],
          breachScenarios: [],
        },
        rawText,
      );
      providerUsed = 'none';
      modelUsed = 'heuristic';
      totalInputTokens = 0;
      totalOutputTokens = 0;
    } else {
      const singleResult = await analyzeSingle(llmText, selectedPrompt, detectedLang);
      analysisResult = enrichAnalysisOutput(singleResult.result, rawText);
      providerUsed = singleResult.provider;
      modelUsed = singleResult.model;
      totalInputTokens = singleResult.inputTokens;
      totalOutputTokens = singleResult.outputTokens;
    }

    const typeKey = normalizeTypeKey(analysisResult.documentType || 'unknown');
    db.run(sql`UPDATE ${documents} SET
      detected_type = ${typeKey},
      detected_type_confidence = ${analysisResult.detectedTypeConfidence || 70},
      needs_type_confirmation = 0,
      updated_at = datetime('now')
      WHERE id = ${documentId}`);

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

    // Clear prior partial analysis if any
    if (existing[0]) {
      db.run(sql`DELETE FROM clauses WHERE analysis_id = ${existing[0].id}`);
      db.run(sql`DELETE FROM risk_items WHERE analysis_id = ${existing[0].id}`);
      db.run(sql`DELETE FROM analysis_results WHERE id = ${existing[0].id}`);
    }
    db.run(sql`DELETE FROM deadlines WHERE document_id = ${documentId}`);

    const analysisId = saveAnalysisResults(
      documentId,
      doc.userId,
      analysisResult,
      totalTime,
      modelUsed,
      preferredLanguage,
    );

    if (analysisId) {
      saveDeadlinesForDocument(documentId, doc.userId, buildDeadlineInputsFromAnalysis(analysisResult));

      try {
        const flags = await runJurisdictionCheck(
          documentId,
          analysisId,
          analysisResult.documentType || typeKey,
        );
        await runConflictDetection(documentId, analysisId, flags);
      } catch (err) {
        console.warn('[process] jurisdiction/conflict skipped:', err instanceof Error ? err.message : err);
      }

      try {
        // Keyword-only path still runs; semantic AI inside is best-effort.
        await runRiskPatternScan(documentId, analysisId);
      } catch (err) {
        console.warn('[process] risk pattern scan skipped:', err instanceof Error ? err.message : err);
      }

      if (counterClausesEnabled()) {
        db.run(sql`UPDATE ${analysisResults} SET counter_clauses_status = 'pending' WHERE id = ${analysisId}`);
        await counterClausesQueue.add('generate-counters', { documentId, userId: doc.userId });
      } else {
        db.run(sql`UPDATE ${analysisResults} SET counter_clauses_status = 'skipped' WHERE id = ${analysisId}`);
      }
    }

    updateDocumentStatus(documentId, 'analyzed');
    createNotification(
      doc.userId,
      'analysis_complete',
      'Analysis Complete',
      `Analysis of "${doc.originalName}" is complete.`,
      documentId,
    );
    persistNow();

    console.log(`[process] doc=${documentId} done in ${totalTime.toFixed(1)}s via ${providerUsed}/${modelUsed}`);
    return getAnalysisBundleForDocument(documentId);
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);

    db.insert(usageLogs).values({
      userId: doc.userId,
      action: 'analysis:failed',
      documentId,
      processingTime: (Date.now() - startTime) / 1000,
    }).run();

    updateDocumentStatus(documentId, 'failed');
    createNotification(
      doc.userId,
      'analysis_failed',
      'Analysis Failed',
      `We couldn't analyze "${doc.originalName}". Open the document to try again.`,
      documentId,
    );
    persistNow();
    console.error(`Analysis failed for document ${documentId}:`, message);
    throw err;
  }
}

export function getAnalysisBundleForDocument(documentId: number): {
  status: string;
  analysis: Record<string, unknown> | null;
  clauses: unknown[];
  riskItems: unknown[];
  deadlines: unknown[];
} {
  const db = getDb();
  const docRows = db.select().from(documents).where(sql`${documents.id} = ${documentId}`).all();
  const analysisRows = db.select().from(analysisResults).where(sql`${analysisResults.documentId} = ${documentId}`).all();
  const analysis = analysisRows[0];

  if (!analysis) {
    return {
      status: docRows[0]?.processingStatus || 'pending',
      analysis: null,
      clauses: [],
      riskItems: [],
      deadlines: [],
    };
  }

  const clauseRows = db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysis.id}`).all();
  const riskRows = db.select().from(riskItems).where(sql`${riskItems.analysisId} = ${analysis.id}`).all();
  const deadlineRows = db.select().from(deadlines).where(sql`${deadlines.documentId} = ${documentId}`).all();

  const parse = (v: string | null) => {
    if (!v) return [];
    try { return JSON.parse(v); } catch { return []; }
  };

  return {
    status: docRows[0]?.processingStatus || 'analyzed',
    analysis: {
      ...analysis,
      keyParties: parse(analysis.keyParties),
      criticalDates: parse(analysis.criticalDates),
      keyObligations: parse(analysis.keyObligations),
      missingClauses: parse(analysis.missingClauses),
      jurisdictionFlags: parse(analysis.jurisdictionFlags),
    },
    clauses: clauseRows,
    riskItems: riskRows,
    deadlines: deadlineRows,
  };
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

  const storagePath = (doc as { storagePath: string }).storagePath;
  if (!storagePath) {
    throw new Error('Document has no stored text and no file path');
  }

  const db = getDb();
  const buffer = await readFile(storagePath);
  const format = extractFormatFromPath(storagePath, (doc as { fileFormat?: string }).fileFormat);
  const { text, method } = await extractDocumentText(buffer, format);
  console.log(`[extract] doc=${documentId} method=${method} chars=${text.length}`);

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

export async function classifyDocument(
  text: string,
  documentLanguage = 'en',
  responseLanguage = 'en',
): Promise<ClassifyOutput> {
  const systemPrompt = appendLanguageInstructions(CLASSIFY_SYSTEM_PROMPT, documentLanguage, responseLanguage);
  const { response } = await callWithFallback(
    {
      systemPrompt,
      userPrompt: buildClassifyUserPrompt(text),
      temperature: 0.2,
    },
    { task: 'classification', language: documentLanguage },
  );

  const parsed = typeof response.text === 'string' ? parseClassifyResponse(response.text) : response.text;
  return ClassifyOutputSchema.parse(parsed);
}

async function analyzeSingle(
  text: string,
  systemPrompt: string,
  documentLanguage = 'en',
): Promise<{ result: AnalysisOutput; provider: string; model: string; inputTokens: number; outputTokens: number }> {
  const estimatedTokens = estimateTotalRequestTokens(systemPrompt, text);
  selectProviderForTokens(estimatedTokens);

  let lastError: string | null = null;

  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    try {
      const prompt = attempt > 0
        ? systemPrompt + `\n\nNOTE: Your previous response failed validation (${lastError}). Ensure the JSON is valid and matches the required structure exactly. No extra fields. All fields must be present.`
        : systemPrompt;

      const userPrompt = buildAnalysisUserPrompt(text);

      const { response, providerUsed } = await callWithFallback(
        { systemPrompt: prompt, userPrompt, temperature: 0.3 },
        { task: 'analysis', language: documentLanguage },
      );

      const parsed = typeof response.text === 'string' ? parseAiResponse(response.text) : response.text;

      const validated = enrichAnalysisOutput(
        AnalysisOutputSchema.parse(parsed),
        text,
      );

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
  documentLanguage = 'en',
): Promise<{ result: AnalysisOutput; provider: string; model: string; inputTokens: number; outputTokens: number }> {
  const chunks = chunkText(fullText);
  const chunkResults: AnalysisOutput[] = [];
  let lastProvider = '';
  let lastModel = '';
  let totalInputTokens = 0;
  let totalOutputTokens = 0;

  for (let i = 0; i < chunks.length; i++) {
    const chunk = chunks[i];
    console.log(`[process] chunk ${i + 1}/${chunks.length} for doc=${documentId}`);

    const text = `[This is part ${i + 1} of ${chunks.length} of a legal document. Analyze this portion and return the full JSON structure with all findings from this section.]\n\n${chunk.text}`;

    const singleResult = await analyzeSingle(text, systemPrompt, documentLanguage);
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
  analysisLanguage = 'en',
): number | null {
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
    jurisdictionCheckStatus: 'pending',
    breachScenarios: JSON.stringify(ai.breachScenarios),
    processingTime,
    aiModelUsed: modelUsed || 'unknown',
    analysisLanguage,
    translations: '{}',
    counterClausesStatus: counterClausesEnabled() ? 'pending' : 'skipped',
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
        pageNumber: clause.pageReference ?? null,
        partyReferences: clause.partyReferences.length > 0
          ? JSON.stringify(clause.partyReferences)
          : null,
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
  }

  return analysisId ?? null;
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

  for (const c of clauseRows) {
    const score = c.riskScore ?? 0;
    if (!shouldPromoteClauseToRisk(score, c.riskReason)) continue;

    const severity = severityFromScore(score);
    const title = (c.clauseTitle || 'Clause').trim();

    db.insert(riskItems).values({
      analysisId,
      clauseId: c.id,
      riskType: c.riskCategory || 'legal',
      title: `${title} risk`,
      description: c.riskReason || c.plainEnglishText || `Review “${title}” carefully.`,
      severity,
      severityScore: score,
      recommendation: c.counterSuggestion || 'Negotiate clearer, fairer wording before you sign.',
      legalReference: '',
    }).run();
  }
}
