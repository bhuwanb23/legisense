import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;
const TAG_LENGTH = 16;
const KEY_LENGTH = 32;

function getKey(): Buffer {
  const hex = process.env.ENCRYPTION_KEY || '';
  if (!hex) throw new Error('ENCRYPTION_KEY is not set. Add a 64-char hex key to .env');

  const key = Buffer.from(hex, 'hex');
  if (key.length !== KEY_LENGTH) {
    throw new Error(`ENCRYPTION_KEY must be 64 hex chars (32 bytes). Got ${hex.length} chars.`);
  }
  return key;
}

export function encryptBuffer(plaintext: Buffer): { encrypted: Buffer; iv: Buffer } {
  const key = getKey();
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
  const key = getKey();

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
  return Boolean(process.env.ENCRYPTION_KEY);
}
