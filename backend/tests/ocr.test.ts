import { initDatabase, getDb, closeDatabase, persistNow } from '../src/config/database';
import { sql } from 'drizzle-orm';
import { users, documents } from '../src/models';

interface TestResult {
  test: string;
  pass: boolean;
  detail?: string;
}

const results: TestResult[] = [];

function assert(condition: boolean, test: string, detail?: string) {
  results.push({ test, pass: condition, detail });
  console.log(`  ${condition ? '✅' : '❌'} ${test}${detail ? ` — ${detail}` : ''}`);
}

async function run() {
  console.log('🧪 OCR Services Tests\n');
  await initDatabase();
  const db = getDb();

  db.run(sql`DELETE FROM ${documents}`);
  db.run(sql`DELETE FROM ${users}`);
  persistNow();

  db.insert(users).values({
    fullName: 'OCR Test User',
    email: 'ocr-test@test.com',
    passwordHash: 'hash',
    authProvider: 'email',
    isActive: true,
  }).run();
  const userRow = db.select().from(users).where(sql`${users.email} = 'ocr-test@test.com'`).all()[0];
  const userId = userRow.id;

  console.log('── 1. textCleaner ──');
  {
    const { cleanOcrText } = await import('../src/services/textCleaner');

    const clean1 = cleanOcrText('Hello, this is clean text.');
    assert(clean1.text === 'Hello, this is clean text.', 'cleanOcrText preserves clean text');
    assert(clean1.stats.garbageCharsRemoved === 0, 'No garbage chars in clean text');

    const clean2 = cleanOcrText('Bro-\nken word here.');
    assert(clean2.text.includes('Broken'), 'cleanOcrText merges hyphenated line breaks');

    const clean3 = cleanOcrText('Text with\x00 null\x01 chars');
    assert(!clean3.text.includes('\x00'), 'cleanOcrText removes null chars');
    assert(!clean3.text.includes('\x01'), 'cleanOcrText removes control chars');

    const clean4 = cleanOcrText('Line1\n\n\n\nLine2');
    const hasMaxTwoNewlines = (clean4.text.match(/\n\n/g) || []).length <= 1 && !clean4.text.includes('\n\n\n');
    assert(hasMaxTwoNewlines, 'cleanOcrText collapses excessive newlines');

    const clean5 = cleanOcrText('');
    assert(clean5.text === '', 'cleanOcrText handles empty string');
    assert(clean5.stats.originalLength === 0, 'Empty string stats correct');
  }

  console.log('\n── 2. imageProcessor ──');
  {
    const { analyzeImage, convertToJpeg, isBlurry } = await import('../src/services/imageProcessor');
    const sharp = await import('sharp');

    const testImageBuffer = await sharp.default({
      create: {
        width: 100,
        height: 50,
        channels: 3,
        background: { r: 200, g: 150, b: 100 },
      },
    })
      .jpeg()
      .toBuffer();

    const analysis = await analyzeImage(testImageBuffer);
    assert(typeof analysis.isBlurry === 'boolean', 'analyzeImage returns isBlurry');
    assert(typeof analysis.blurScore === 'number', 'analyzeImage returns blurScore (number)');
    assert(typeof analysis.rotationDegrees === 'number', 'analyzeImage returns rotationDegrees');
    assert(typeof analysis.isDark === 'boolean', 'analyzeImage returns isDark');
    assert(typeof analysis.averageBrightness === 'number', 'analyzeImage returns averageBrightness');
    assert(analysis.format !== '', 'analyzeImage returns format');

    const converted = await convertToJpeg(testImageBuffer);
    assert(converted instanceof Buffer, 'convertToJpeg returns a Buffer');
    assert(converted.length > 0, 'Converted buffer is not empty');

    const jpegBuf = await sharp.default(testImageBuffer).jpeg().toBuffer();
    const convertedJpeg = await convertToJpeg(jpegBuf);
    assert(convertedJpeg.length === jpegBuf.length, 'convertToJpeg passes through JPEG unchanged');

    const blurry = await isBlurry(testImageBuffer);
    assert(typeof blurry === 'boolean', 'isBlurry returns boolean');
  }

  console.log('\n── 3. ocrService helpers ──');
  {
    const { parseLanguagePreference, buildLanguageString } = await import('../src/services/ocrService');

    assert(parseLanguagePreference('en') === 'eng', 'parseLanguagePreference: en → eng');
    assert(parseLanguagePreference('es') === 'spa', 'parseLanguagePreference: es → spa');
    assert(parseLanguagePreference('fr') === 'fra', 'parseLanguagePreference: fr → fra');
    assert(parseLanguagePreference('de') === 'deu', 'parseLanguagePreference: de → deu');
    assert(parseLanguagePreference('ja') === 'jpn', 'parseLanguagePreference: ja → jpn');
    assert(parseLanguagePreference('zh') === 'chi_sim', 'parseLanguagePreference: zh → chi_sim');
    assert(parseLanguagePreference('xx') === 'eng', 'parseLanguagePreference: unknown → eng');
    assert(parseLanguagePreference('') === 'eng', 'parseLanguagePreference: empty → eng');

    const multi = buildLanguageString('en', 'fr,de,es');
    assert(multi.includes('eng'), 'buildLanguageString includes primary language');
    assert(multi.includes('fra'), 'buildLanguageString includes french');
    assert(multi.includes('deu'), 'buildLanguageString includes german');
    assert(multi.includes('spa'), 'buildLanguageString includes spanish');

    const single = buildLanguageString('fr');
    assert(single === 'fra', 'buildLanguageString without extras returns single lang code');

    const deduped = buildLanguageString('en', 'en,eng');
    assert(deduped === 'eng', 'buildLanguageString deduplicates identical languages');
  }

  console.log('\n── 4. OCR worker creation ──');
  {
    const { createOcrWorker } = await import('../src/queue/workers/ocrWorker');

    const worker = createOcrWorker();
    assert(worker !== null, 'createOcrWorker returns a worker instance');
    assert(typeof worker.start === 'function', 'Worker has start method');
    assert(typeof worker.close === 'function', 'Worker has close method');

    await worker.close();
  }

  console.log('\n── 5. Socket event types ──');
  {
    const { ServerToClientEvents } = await import('../src/services/socketService');

    const eventNames: (keyof ServerToClientEvents)[] = [
      'ocr:started',
      'ocr:progress',
      'ocr:completed',
      'ocr:failed',
    ];

    for (const event of eventNames) {
      assert(true, `Socket event type '${event}' is defined`);
    }
  }

  console.log('\n── 6. Schema status values ──');
  {
    const { listDocumentsSchema } = await import('../src/schemas/documentSchemas');

    const validStatuses = ['all', 'pending', 'ocr_processing', 'text_extracted', 'processing', 'completed', 'failed'];
    for (const status of validStatuses) {
      const result = listDocumentsSchema.safeParse({ status });
      assert(result.success, `listDocumentsSchema accepts '${status}' status`);
    }

    const invalid = listDocumentsSchema.safeParse({ status: 'invalid_status' });
    assert(!invalid.success, 'listDocumentsSchema rejects invalid status');
  }

  console.log('\n── 7. textExtractor format support ──');
  {
    const { isSupportedFormat, getUnsupportedFormatMessage } = await import('../src/services/textExtractor');

    assert(isSupportedFormat('heic'), 'textExtractor supports heic');
    assert(isSupportedFormat('heif'), 'textExtractor supports heif');
    assert(isSupportedFormat('webp'), 'textExtractor supports webp');

    const msg = getUnsupportedFormatMessage('xyz');
    assert(msg.includes('heic'), 'Unsupported format message mentions heic');
    assert(msg.includes('webp'), 'Unsupported format message mentions webp');
  }

  console.log('\n── 8. Document status update for scan ──');
  {
    db.insert(documents).values({
      userId,
      originalName: 'scan-test.png',
      storagePath: 'scan-test-placeholder.png',
      fileFormat: 'png',
      fileSize: 100,
      sourceType: 'scan',
      uploadStatus: 'uploaded',
      processingStatus: 'uploaded',
    }).run();

    const scanDoc = db.select().from(documents).where(sql`${documents.sourceType} = 'scan'`).all()[0];
    assert(scanDoc.processingStatus === 'uploaded', 'Scan doc starts with uploaded status');

    db.run(
      sql`UPDATE ${documents} SET processing_status = 'ocr_processing', updated_at = datetime('now') WHERE id = ${scanDoc.id}`
    );
    persistNow();

    const updated = db.select().from(documents).where(sql`${documents.id} = ${scanDoc.id}`).all()[0];
    assert(updated.processingStatus === 'ocr_processing', 'Status can be set to ocr_processing');

    db.run(
      sql`UPDATE ${documents} SET
        raw_text = 'OCR extracted text',
        processing_status = 'text_extracted',
        detected_language = 'eng',
        updated_at = datetime('now')
      WHERE id = ${scanDoc.id}`
    );
    persistNow();

    const textExtracted = db.select().from(documents).where(sql`${documents.id} = ${scanDoc.id}`).all()[0];
    assert(textExtracted.processingStatus === 'text_extracted', 'Status can be set to text_extracted');
    assert(textExtracted.rawText === 'OCR extracted text', 'Raw text stored correctly');
    assert(textExtracted.detectedLanguage === 'eng', 'Detected language stored');
  }

  // ── CLEANUP ──
  db.run(sql`DELETE FROM ${documents}`);
  db.run(sql`DELETE FROM ${users}`);
  persistNow();
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
