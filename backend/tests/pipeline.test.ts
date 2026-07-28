import fs from 'fs';
import path from 'path';

import { initDatabase, getDb, closeDatabase, persistNow } from '../src/config/database';
import { sql } from 'drizzle-orm';
import { documents, users, analysisResults, clauses, riskItems, deadlines, chatMessages } from '../src/models';

import { saveFile, readFile, deleteFile, getUploadDir } from '../src/storage/fileStorage';
import { extractText, isSupportedFormat, getUnsupportedFormatMessage } from '../src/services/textExtractor';
import { queueService, type Job } from '../src/services/queueService';
import { buildAnalysisUserPrompt, parseAiResponse } from '../src/prompts/analysisPrompt';
import { startAnalysisWorker } from '../src/jobs/analysisWorker';

const results: { test: string; pass: boolean; detail?: string }[] = [];

function assert(condition: boolean, test: string, detail?: string) {
  results.push({ test, pass: condition, detail });
  console.log(`  ${condition ? '✅' : '❌'} ${test}${detail ? ` — ${detail}` : ''}`);
}

async function run() {
  console.log('🧪 File Processing Pipeline Tests\n');

  await initDatabase();
  const db = getDb();

  // ── Clean slate ──
  db.run(sql`DELETE FROM ${deadlines}`);
  db.run(sql`DELETE FROM ${riskItems}`);
  db.run(sql`DELETE FROM ${clauses}`);
  db.run(sql`DELETE FROM ${analysisResults}`);
  db.run(sql`DELETE FROM ${chatMessages}`);
  db.run(sql`DELETE FROM ${documents}`);
  db.run(sql`DELETE FROM ${users}`);
  persistNow();

  // ── Seed a test user ──
  db.insert(users).values({
    email: 'pipeline-test@test.com',
    passwordHash: 'hash',
    fullName: 'Pipeline Tester',
    authProvider: 'local',
    isActive: true,
  }).run();
  const userRows = db.select().from(users).where(sql`${users.email} = 'pipeline-test@test.com'`).all();
  const testUserId = userRows[0].id;

  // ═══════════════════════════════════════════════════
  //  1. FILE STORAGE
  // ═══════════════════════════════════════════════════
  console.log('\n── 1. File Storage ──');

  const testContent = Buffer.from('This is a test legal document for pipeline testing.');
  const savedPath = saveFile(testContent, 'test-agreement.txt', 'txt');
  assert(typeof savedPath === 'string' && savedPath.length > 0, 'saveFile returns a filename');
  assert(savedPath.endsWith('.txt'), 'saveFile preserves .txt extension', savedPath);
  assert(fs.existsSync(path.join(getUploadDir(), savedPath)), 'File exists on disk');

  const readBuffer = readFile(savedPath);
  assert(readBuffer.equals(testContent), 'readFile returns original content');
  assert(readBuffer.length === testContent.length, 'readFile buffer length matches');

  const savedPdf = saveFile(Buffer.from('PDF fake'), 'contract.pdf', 'pdf');
  assert(savedPdf.endsWith('.pdf'), 'saveFile preserves .pdf extension', savedPdf);

  const savedDocx = saveFile(Buffer.from('DOCX fake'), 'agreement.docx', 'docx');
  assert(savedDocx.endsWith('.docx'), 'saveFile preserves .docx extension', savedDocx);

  deleteFile(savedPdf);
  assert(!fs.existsSync(path.join(getUploadDir(), savedPdf)), 'deleteFile removes file');

  let threwOnMissing = false;
  try { readFile('nonexistent-file.txt'); } catch { threwOnMissing = true; }
  assert(threwOnMissing, 'readFile throws for missing file');

  // ═══════════════════════════════════════════════════
  //  2. TEXT EXTRACTION
  // ═══════════════════════════════════════════════════
  console.log('\n── 2. Text Extraction ──');

  assert(isSupportedFormat('pdf'), 'isSupportedFormat(pdf)');
  assert(isSupportedFormat('docx'), 'isSupportedFormat(docx)');
  assert(isSupportedFormat('txt'), 'isSupportedFormat(txt)');
  assert(isSupportedFormat('png'), 'isSupportedFormat(png) = true (OCR support)');
  assert(!isSupportedFormat('doc'), 'isSupportedFormat(doc) = false');
  const txtResult = await extractText(Buffer.from('Hello legal world'), 'txt');

  assert(txtResult.text === 'Hello legal world', 'extractText for txt returns raw text');

  const docMessage = getUnsupportedFormatMessage('doc');
  assert(docMessage.includes('.docx'), 'getUnsupportedFormatMessage for .doc mentions .docx');

  const unknownMessage = getUnsupportedFormatMessage('xyz');
  assert(unknownMessage.includes('xyz'), 'getUnsupportedFormatMessage for unknown format mentions it');

  // ═══════════════════════════════════════════════════
  //  3. QUEUE SERVICE
  // ═══════════════════════════════════════════════════
  console.log('\n── 3. Queue Service ──');

  // Reset queue by creating a fresh instance-like state
  // The queueService is a singleton, so we test its methods directly
  let workerCalledWith: { documentId: number; userId: number } | null = null;
  queueService.setWorker(async (docId, userId) => {
    workerCalledWith = { documentId: docId, userId };
  });

  const job: Job = queueService.enqueue(999, testUserId);
  assert(typeof job.id === 'string', 'enqueue returns job with id');
  assert(job.documentId === 999, 'enqueue job has correct documentId');
  assert(job.userId === testUserId, 'enqueue job has correct userId');
  assert(job.status === 'pending' || job.status === 'processing' || job.status === 'completed', 'enqueue job has valid status');

  // Give async processing a tick
  await new Promise((r) => setTimeout(r, 50));

  const stats = queueService.getStats();
  assert(stats.total >= 1, 'queue has at least 1 job', `total=${stats.total}`);

  const fetched = queueService.getJob(job.id);
  assert(fetched !== undefined, 'getJob finds enqueued job');
  assert(fetched!.id === job.id, 'getJob returns correct job');

  const docJobs = queueService.getJobsByDocument(999);
  assert(docJobs.length >= 1, 'getJobsByDocument finds jobs for doc 999');

  // ═══════════════════════════════════════════════════
  //  4. PROMPT BUILDER
  // ═══════════════════════════════════════════════════
  console.log('\n── 4. Prompt Builder ──');

  const shortPrompt = buildAnalysisUserPrompt('This is a short contract.');
  assert(shortPrompt.includes('This is a short contract.'), 'buildAnalysisUserPrompt includes document text');
  assert(shortPrompt.includes('Analyze'), 'buildAnalysisUserPrompt has instruction');

  const longDoc = 'A'.repeat(60000);
  const longPrompt = buildAnalysisUserPrompt(longDoc);
  assert(longPrompt.length < 60000, 'buildAnalysisUserPrompt truncates long documents');
  assert(longPrompt.includes('[Document truncated due to length]'), 'Truncation notice present');

  // ═══════════════════════════════════════════════════
  //  5. AI RESPONSE PARSER
  // ═══════════════════════════════════════════════════
  console.log('\n── 5. AI Response Parser ──');

  const validJson = '{"documentType":"NDA","overallRiskScore":42}';
  const parsed = parseAiResponse(validJson);
  assert(parsed.documentType === 'NDA', 'parseAiResponse parses valid JSON');

  const markdownJson = '```json\n{"documentType":"Rental"}\n```';
  const parsedMd = parseAiResponse(markdownJson);
  assert(parsedMd.documentType === 'Rental', 'parseAiResponse strips markdown fences');

  const trimmedJson = '  {"documentType":"Employment"}  ';
  const parsedTrimmed = parseAiResponse(trimmedJson);
  assert(parsedTrimmed.documentType === 'Employment', 'parseAiResponse handles whitespace');

  let parseFailed = false;
  try { parseAiResponse('not json at all'); } catch { parseFailed = true; }
  assert(parseFailed, 'parseAiResponse throws on invalid JSON');

  // ═══════════════════════════════════════════════════
  //  6. DOCUMENT RECORD CREATION
  // ═══════════════════════════════════════════════════
  console.log('\n── 6. Document Record CRUD ──');

  db.insert(documents).values({
    userId: testUserId,
    originalName: 'test-nda.pdf',
    storagePath: savedPath,
    fileFormat: 'txt',
    fileSize: testContent.length,
    sourceType: 'file_upload',
    uploadStatus: 'uploaded',
    processingStatus: 'pending',
  }).run();

  const docRows = db.select().from(documents).where(sql`${documents.userId} = ${testUserId}`).all();
  assert(docRows.length >= 1, 'Document record created');
  assert(docRows[0].originalName === 'test-nda.pdf', 'Document has correct originalName');
  assert(docRows[0].processingStatus === 'pending', 'Document starts as pending');

  const testDocId = docRows[0].id;

  // Update status
  db.run(sql`UPDATE ${documents} SET processing_status = 'processing' WHERE id = ${testDocId}`);
  const updatedRows = db.select().from(documents).where(sql`${documents.id} = ${testDocId}`).all();
  assert(updatedRows[0].processingStatus === 'processing', 'Document status updated to processing');

  // ═══════════════════════════════════════════════════
  //  7. ANALYSIS RESULTS SAVING
  // ═══════════════════════════════════════════════════
  console.log('\n── 7. Analysis Results ──');

  db.insert(analysisResults).values({
    documentId: testDocId,
    userId: testUserId,
    documentType: 'NDA',
    detectedTypeConfidence: 85,
    overallRiskScore: 65,
    riskLevel: 'medium',
    fairnessScore: 42,
    favorsParty: 'Party B',
    summary: 'This is a non-disclosure agreement between two parties.',
    keyParties: JSON.stringify([{ name: 'Party A', role: 'Discloser', obligations: ['Keep secrets'] }]),
    criticalDates: JSON.stringify([{ label: 'Effective Date', date: '2025-01-01', urgency: 'medium' }]),
    keyObligations: JSON.stringify([{ party: 'Party A', obligation: 'Disclose confidential info' }]),
    missingClauses: JSON.stringify(['Governing law clause']),
    jurisdictionFlags: JSON.stringify([]),
    processingTime: 3.2,
    aiModelUsed: 'gemini-1.5-flash',
  }).run();

  const analysisRows = db.select().from(analysisResults).where(sql`${analysisResults.documentId} = ${testDocId}`).all();
  assert(analysisRows.length >= 1, 'Analysis result saved');
  assert(analysisRows[0].documentType === 'NDA', 'Analysis has correct documentType');
  assert(analysisRows[0].overallRiskScore === 65, 'Analysis has correct risk score');
  assert(analysisRows[0].riskLevel === 'medium', 'Analysis has correct risk level');

  const analysisId = analysisRows[0].id;

  // ═══════════════════════════════════════════════════
  //  8. CLAUSES, RISKS, DEADLINES
  // ═══════════════════════════════════════════════════
  console.log('\n── 8. Clauses, Risks, Deadlines ──');

  db.insert(clauses).values({
    documentId: testDocId,
    analysisId,
    clauseNumber: 1,
    clauseTitle: 'Confidentiality',
    originalText: 'Party A agrees to keep all info confidential.',
    plainEnglishText: 'You must keep secrets secret.',
    riskLevel: 'high',
    riskScore: 80,
    riskReason: 'No exceptions defined',
    riskCategory: 'legal',
    counterSuggestion: 'Add standard exceptions for publicly available info.',
  }).run();

  const clauseRows = db.select().from(clauses).where(sql`${clauses.analysisId} = ${analysisId}`).all();
  assert(clauseRows.length >= 1, 'Clause saved');
  assert(clauseRows[0].clauseTitle === 'Confidentiality', 'Clause has correct title');
  assert(clauseRows[0].riskScore === 80, 'Clause has correct risk score');

  db.insert(riskItems).values({
    analysisId,
    riskType: 'legal',
    title: 'Overly broad confidentiality',
    description: 'The confidentiality clause has no exceptions.',
    severity: 'high',
    severityScore: 80,
    recommendation: 'Add carve-outs for publicly available information.',
    legalReference: 'Standard NDA practice',
  }).run();

  const riskRows = db.select().from(riskItems).where(sql`${riskItems.analysisId} = ${analysisId}`).all();
  assert(riskRows.length >= 1, 'Risk item saved');
  assert(riskRows[0].title === 'Overly broad confidentiality', 'Risk has correct title');

  db.insert(deadlines).values({
    documentId: testDocId,
    userId: testUserId,
    title: 'NDA Expiration',
    description: 'The NDA expires one year from signing.',
    dueDate: '2026-01-01',
    recurrence: 'one-time',
  }).run();

  const deadlineRows = db.select().from(deadlines).where(sql`${deadlines.documentId} = ${testDocId}`).all();
  assert(deadlineRows.length >= 1, 'Deadline saved');
  assert(deadlineRows[0].title === 'NDA Expiration', 'Deadline has correct title');

  // ═══════════════════════════════════════════════════
  //  9. ANALYSIS WORKER SETUP
  // ═══════════════════════════════════════════════════
  console.log('\n── 9. Analysis Worker ──');

  let workerSet = false;
  try {
    startAnalysisWorker();
    workerSet = true;
  } catch {
    workerSet = false;
  }
  assert(workerSet, 'startAnalysisWorker runs without error');

  // ═══════════════════════════════════════════════════
  //  10. INTEGRATION: Upload → Status → Result flow
  // ═══════════════════════════════════════════════════
  console.log('\n── 10. Integration Flow ──');

  // Simulate the flow: create doc → update status → save analysis → read back
  const flowDoc = saveFile(Buffer.from('Flow test contract content'), 'flow-contract.txt', 'txt');

  db.insert(documents).values({
    userId: testUserId,
    originalName: 'flow-contract.txt',
    storagePath: flowDoc,
    fileFormat: 'txt',
    fileSize: 29,
    sourceType: 'file_upload',
    uploadStatus: 'uploaded',
    processingStatus: 'pending',
  }).run();

  const flowDocRows = db.select().from(documents).where(sql`${documents.storagePath} = ${flowDoc}`).all();
  const flowDocId = flowDocRows[0].id;

  // Simulate processing
  db.run(sql`UPDATE ${documents} SET processing_status = 'processing' WHERE id = ${flowDocId}`);
  const processing = db.select().from(documents).where(sql`${documents.id} = ${flowDocId}`).all();
  assert(processing[0].processingStatus === 'processing', 'Flow: doc marked as processing');

  // Simulate completion
  db.run(sql`UPDATE ${documents} SET processing_status = 'completed' WHERE id = ${flowDocId}`);
  db.insert(analysisResults).values({
    documentId: flowDocId,
    userId: testUserId,
    documentType: 'Contract',
    detectedTypeConfidence: 70,
    overallRiskScore: 30,
    riskLevel: 'low',
    fairnessScore: 55,
    favorsParty: 'Balanced',
    summary: 'A simple contract.',
    keyParties: JSON.stringify([]),
    criticalDates: JSON.stringify([]),
    keyObligations: JSON.stringify([]),
    missingClauses: JSON.stringify([]),
    jurisdictionFlags: JSON.stringify([]),
    processingTime: 1.5,
    aiModelUsed: 'gemini-1.5-flash',
  }).run();

  const finalDoc = db.select().from(documents).where(sql`${documents.id} = ${flowDocId}`).all();
  const finalAnalysis = db.select().from(analysisResults).where(sql`${analysisResults.documentId} = ${flowDocId}`).all();
  assert(finalDoc[0].processingStatus === 'completed', 'Flow: final doc status is completed');
  assert(finalAnalysis.length >= 1, 'Flow: analysis exists');
  assert(finalAnalysis[0].riskLevel === 'low', 'Flow: correct risk level');

  // ═══════════════════════════════════════════════════
  //  CLEANUP & SUMMARY
  // ═══════════════════════════════════════════════════
  deleteFile(savedPath);
  deleteFile(flowDoc);
  deleteFile(savedDocx);

  closeDatabase();

  console.log('\n═══════════════════════════════════════════');
  const passed = results.filter((r) => r.pass).length;
  const failed = results.filter((r) => !r.pass).length;
  console.log(`\n  ${passed} passed, ${failed} failed, ${results.length} total`);
  if (failed > 0) {
    console.log('\n  Failed tests:');
    results.filter((r) => !r.pass).forEach((r) => console.log(`    ❌ ${r.test}${r.detail ? ` — ${r.detail}` : ''}`));
  }
  console.log('');
  process.exit(failed > 0 ? 1 : 0);
}

run().catch((err) => {
  console.error('Unhandled test error:', err);
  process.exit(1);
});
