import { Worker } from '../worker';
import { getDb } from '../../config/database';
import { documents, users } from '../../models';
import { sql } from 'drizzle-orm';
import { readFile } from '../../storage/fileStorage';
import { ocrImage, OcrResult, buildLanguageString } from '../../services/ocrService';
import { analyzeImage, autoRotate } from '../../services/imageProcessor';
import { cleanOcrText } from '../../services/textCleaner';
import { mistralOcrImage } from '../../services/mistralOcrService';
import { emitToUser, emitToDocument } from '../../services/socketService';
import { persistNow } from '../../config/database';
import { encryptText, isEncryptionConfigured } from '../../services/encryptionService';

const MISTRAL_CONFIDENCE_THRESHOLD = 70;

export function createOcrWorker(): Worker {
  const worker = new Worker('ocr-processing', async (job) => {
    const { documentId, userId } = job.data as { documentId: number; userId: number };
    const db = getDb();

    const docRows = db
      .select()
      .from(documents)
      .where(sql`${documents.id} = ${documentId} AND ${documents.userId} = ${userId}`);

    if (docRows.length === 0) {
      emitToUser(userId, 'ocr:failed', { documentId, error: 'Document not found' });
      return;
    }

    const doc = docRows[0];

    await db.execute(
      sql`UPDATE ${documents} SET processing_status = 'ocr_processing', updated_at = NOW() WHERE id = ${documentId}`
    );
    persistNow();
    emitToUser(userId, 'ocr:started', { documentId });

    let imageBuffer: Buffer;
    try {
      imageBuffer = await readFile(doc.storagePath);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to read image file';
      failOcr(db, documentId, userId, msg);
      return;
    }

    let imageAnalysis;
    try {
      imageAnalysis = await analyzeImage(imageBuffer);
    } catch {
      imageAnalysis = { isBlurry: false, blurScore: 0, rotationDegrees: 0, isDark: false, averageBrightness: 128, format: 'unknown', width: 0, height: 0 };
    }

    const warnings: Array<{ type: string; message: string }> = [];

    if (imageAnalysis.isBlurry) {
      warnings.push({ type: 'blurry', message: 'Image appears blurry. OCR accuracy may be reduced.' });
    }
    if (imageAnalysis.isDark) {
      warnings.push({ type: 'dark', message: 'Image appears very dark. Consider using flash or better lighting.' });
    }
    if (imageAnalysis.rotationDegrees !== 0) {
      emitToUser(userId, 'ocr:progress', { documentId, progress: 15, stage: 'Auto-rotating image' });
      try {
        imageBuffer = await autoRotate(imageBuffer);
        warnings.push({ type: 'rotated', message: `Image was auto-rotated by ${imageAnalysis.rotationDegrees} degrees.` });
      } catch {
        warnings.push({ type: 'rotation_failed', message: 'Auto-rotation failed. Processing as-is.' });
      }
    }

    let languageString = 'eng';
    try {
      const userRecords = db
        .select()
        .from(users)
        .where(sql`${users.id} = ${userId}`);

      if (userRecords.length > 0) {
        const prefLang = (userRecords[0] as Record<string, unknown>).preferredLanguage as string | undefined;
        languageString = buildLanguageString(prefLang || 'en');
      }
    } catch {
      languageString = 'eng';
    }

    emitToUser(userId, 'ocr:progress', { documentId, progress: 30, stage: 'Running OCR' });

    let ocrResult: OcrResult;
    let methodUsed: 'tesseract' | 'mistral' = 'tesseract';

    try {
      ocrResult = await ocrImage(imageBuffer, { language: languageString, osd: false });
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Tesseract OCR failed';
      failOcr(db, documentId, userId, msg);
      return;
    }

    if (ocrResult.confidence < MISTRAL_CONFIDENCE_THRESHOLD) {
      emitToUser(userId, 'ocr:progress', {
        documentId,
        progress: 60,
        stage: `Tesseract confidence low (${ocrResult.confidence.toFixed(0)}%). Trying Mistral OCR fallback...`,
      });

      if (process.env.MISTRAL_API_KEY) {
        try {
          ocrResult = await mistralOcrImage(imageBuffer, { language: languageString });
          methodUsed = 'mistral';
          warnings.push({ type: 'mistral_fallback', message: `Tesseract confidence was low. Used Mistral OCR fallback.` });
        } catch (err2) {
          warnings.push({ type: 'mistral_fallback_failed', message: `Mistral OCR fallback failed: ${err2 instanceof Error ? err2.message : 'unknown error'}. Using Tesseract result.` });
        }
      } else {
        warnings.push({ type: 'tesseract_low_confidence', message: `OCR confidence is low (${ocrResult.confidence.toFixed(0)}%). Set MISTRAL_API_KEY for fallback.` });
      }
    }

    if (ocrResult.confidence < 30) {
      warnings.push({ type: 'handwritten_warning', message: 'Very low OCR confidence. Document may contain handwriting or unusual fonts.' });
    }

    emitToUser(userId, 'ocr:progress', { documentId, progress: 80, stage: 'Cleaning extracted text' });

    const cleaned = cleanOcrText(ocrResult.text);

    let storedText = cleaned.text;
    let storedIv: string | null = null;
    if (isEncryptionConfigured()) {
      const { ciphertext, iv } = encryptText(cleaned.text);
      storedText = ciphertext;
      storedIv = iv;
    }

    await db.execute(
      sql`UPDATE ${documents} SET
        raw_text = ${storedText},
        encryption_iv = ${storedIv},
        processing_status = 'text_extracted',
        detected_language = ${ocrResult.languageUsed},
        updated_at = NOW()
      WHERE id = ${documentId}`
    );
    persistNow();

    const eventData = {
      documentId,
      textLength: cleaned.text.length,
      confidence: ocrResult.confidence,
      method: methodUsed,
      warnings: warnings.length > 0 ? warnings : undefined,
      rotation: ocrResult.rotation || undefined,
    };

    emitToUser(userId, 'ocr:completed', eventData);
    emitToDocument(documentId, 'ocr:completed', eventData);
  }, { concurrency: 1 });

  return worker;
}

function failOcr(db: ReturnType<typeof getDb>, documentId: number, userId: number, error: string): void {
  await db.execute(
    sql`UPDATE ${documents} SET processing_status = 'failed', updated_at = NOW() WHERE id = ${documentId}`
  );
  persistNow();
  emitToUser(userId, 'ocr:failed', { documentId, error });
}
