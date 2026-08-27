import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;
const TAG_LENGTH = 16;
const KEY_LENGTH = 32;

let cachedKey: Buffer | null = null;
let keyChecked = false;

/**
 * Returns the encryption key, or null when encryption is not usable.
 * An invalid ENCRYPTION_KEY logs a warning and disables encryption instead
 * of throwing on every request (which would 500 all uploads).
 */
function getKey(): Buffer | null {
  if (keyChecked) return cachedKey;
  keyChecked = true;
  const hex = process.env.ENCRYPTION_KEY || '';
  if (!hex) return null;

  const key = Buffer.from(hex, 'hex');
  if (key.length !== KEY_LENGTH || !/^[0-9a-fA-F]{64}$/.test(hex)) {
    console.warn(`ENCRYPTION_KEY is invalid (must be 64 hex chars, got ${hex.length} chars). Encryption at rest is DISABLED.`);
    return null;
  }
  cachedKey = key;
  return key;
}

function requireKey(): Buffer {
  const key = getKey();
  if (!key) throw new Error('Encryption is not configured (ENCRYPTION_KEY missing or invalid)');
  return key;
}

export function encryptBuffer(plaintext: Buffer): { encrypted: Buffer; iv: Buffer } {
  const key = requireKey();
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

  const encrypted = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const tag = cipher.getAuthTag();

  return {
    encrypted: Buffer.concat([encrypted, tag]),
    iv,
  };
}

export function decryptBuffer(encrypted: Buffer, iv: Buffer): Buffer {
  const key = requireKey();

  const ciphertext = encrypted.subarray(0, encrypted.length - TAG_LENGTH);
  const tag = encrypted.subarray(encrypted.length - TAG_LENGTH);

  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(tag);

  return Buffer.concat([decipher.update(ciphertext), decipher.final()]);
}

export function encryptText(plaintext: string): { ciphertext: string; iv: string } {
  const { encrypted, iv } = encryptBuffer(Buffer.from(plaintext, 'utf-8'));
  return {
    ciphertext: encrypted.toString('hex'),
    iv: iv.toString('hex'),
  };
}

export function decryptText(ciphertext: string, ivHex: string): string {
  const encrypted = Buffer.from(ciphertext, 'hex');
  const iv = Buffer.from(ivHex, 'hex');
  return decryptBuffer(encrypted, iv).toString('utf-8');
}

export function isEncryptionConfigured(): boolean {
  return getKey() !== null;
}
