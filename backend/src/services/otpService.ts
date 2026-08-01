import crypto from 'crypto';
import nodemailer from 'nodemailer';

interface OtpEntry {
  hashedOtp: string;
  expiresAt: number;
}

const otpStore = new Map<string, OtpEntry>();

function generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function hashOtp(otp: string): string {
  return crypto.createHash('sha256').update(otp).digest('hex');
}

export async function requestOtp(email: string): Promise<{ otp?: string }> {
  const otp = generateOtp();
  const hashedOtp = hashOtp(otp);
  const expiresAt = Date.now() + 10 * 60 * 1000;

  otpStore.set(email, { hashedOtp, expiresAt });

  const isDev = process.env.NODE_ENV !== 'production';
  const smtpConfigured = process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS;

  if (smtpConfigured && !isDev) {
    try {
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: Number(process.env.SMTP_PORT) || 587,
        secure: process.env.SMTP_SECURE === 'true',
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS,
        },
      });

      await transporter.sendMail({
        from: process.env.SMTP_FROM || 'noreply@legisense.app',
        to: email,
        subject: 'Your Legisense OTP Code',
        html: `
          <h2>Your OTP Code</h2>
          <p>Your one-time password is:</p>
          <h1 style="font-size: 32px; letter-spacing: 4px;">${otp}</h1>
          <p>This code expires in 10 minutes.</p>
        `,
      });
    } catch (err) {
      console.error('Failed to send OTP email:', err);
    }
  } else if (isDev) {
    console.log(`[DEV] OTP for ${email}: ${otp}`);
    return { otp };
  }

  return {};
}

export function verifyOtp(email: string, otp: string): boolean {
  const entry = otpStore.get(email);

  if (!entry) return false;
  if (Date.now() > entry.expiresAt) {
    otpStore.delete(email);
    return false;
  }

  const hashedInputOtp = hashOtp(otp);
  const isValid = hashedInputOtp === entry.hashedOtp;

  if (isValid) {
    otpStore.delete(email);
  }

  return isValid;
}

export function clearOtp(email: string): void {
  otpStore.delete(email);
}
