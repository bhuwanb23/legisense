import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { ocrImage, isImage, terminateOcr } from '../src/services/ocrService';
import { scrapeUrl, isValidUrl } from '../src/services/urlScraper';

describe('OCR Service', () => {
  after(async () => {
    await terminateOcr();
  });

  it('isImage detects PNG header', async () => {
    const png = Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    assert.equal(await isImage(png), true);
  });

  it('isImage detects JPEG header', async () => {
    const jpeg = Buffer.from([0xFF, 0xD8, 0xFF, 0xE0]);
    assert.equal(await isImage(jpeg), true);
  });

  it('isImage returns false for text', async () => {
    assert.equal(await isImage(Buffer.from('not an image')), false);
  });

  it('isImage returns false for empty buffer', async () => {
    assert.equal(await isImage(Buffer.alloc(0)), false);
  });

  it('isImage returns false for short buffer', async () => {
    assert.equal(await isImage(Buffer.from([0x00])), false);
  });
});

describe('URL Scraper', () => {
  it('isValidUrl accepts https', () => {
    assert.equal(isValidUrl('https://example.com'), true);
  });

  it('isValidUrl accepts http', () => {
    assert.equal(isValidUrl('http://example.com'), true);
  });

  it('isValidUrl rejects ftp', () => {
    assert.equal(isValidUrl('ftp://example.com'), false);
  });

  it('isValidUrl rejects garbage', () => {
    assert.equal(isValidUrl('not a url'), false);
  });

  it('isValidUrl rejects empty string', () => {
    assert.equal(isValidUrl(''), false);
  });

  it('scrapeUrl fetches and parses a real URL', async () => {
    const result = await scrapeUrl('https://example.com');
    assert.ok(result.title.length > 0);
    assert.ok(result.text.includes('Example Domain'));
    assert.equal(result.url, 'https://example.com');
  });

  it('scrapeUrl rejects invalid URL', async () => {
    await assert.rejects(() => scrapeUrl('not-a-url'), /Invalid URL/);
  });

  it('scrapeUrl rejects non-HTTP protocol', async () => {
    await assert.rejects(() => scrapeUrl('ftp://example.com'), /Invalid URL/);
  });
});
