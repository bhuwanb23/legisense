import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import jwt from 'jsonwebtoken';

import {
  AppError,
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  ValidationError,
  TooManyRequestsError,
  FileTooLargeError,
  InvalidFileTypeError,
} from '../src/utils/errors';

import { generateToken, verifyToken } from '../src/middleware/auth';
import { validate, sanitizeString, sanitizeObject } from '../src/middleware/validate';
import { errorHandler, notFoundHandler } from '../src/middleware/errorHandler';
import { ALLOWED_FILE_CONFIG } from '../src/middleware/fileValidator';

const results: { test: string; pass: boolean; detail?: string }[] = [];

function assert(condition: boolean, test: string, detail?: string) {
  results.push({ test, pass: condition, detail });
  console.log(`  ${condition ? '✅' : '❌'} ${test}${detail ? ` — ${detail}` : ''}`);
}

function mockReq(overrides?: Partial<Request>): Request {
  return {
    headers: {},
    method: 'GET',
    originalUrl: '/test',
    ip: '127.0.0.1',
    socket: { remoteAddress: '127.0.0.1' },
    ...overrides,
  } as unknown as Request;
}

function mockRes(): Response {
  const res = {
    statusCode: 200,
    body: null as unknown,
    finished: false,
  } as unknown as Response;

  Object.defineProperty(res, 'status', {
    value: (code: number) => {
      res.statusCode = code;
      return res;
    },
    writable: true,
    configurable: true,
  });

  Object.defineProperty(res, 'json', {
    value: (data: unknown) => {
      res.body = data;
      res.finished = true;
      return res;
    },
    writable: true,
    configurable: true,
  });

  return res;
}

function mockNext(): NextFunction & { called: boolean; arg?: unknown } {
  const fn = ((...args: unknown[]) => {
    fn.called = true;
    fn.arg = args[0];
  }) as NextFunction & { called: boolean; arg?: unknown };
  fn.called = false;
  return fn;
}

// ─── Error Classes ───

function testErrorClasses() {
  console.log('\n🚨 Testing Error Classes');

  const appErr = new AppError('test', 400, 'TEST_CODE');
  assert(appErr.message === 'test', 'AppError message');
  assert(appErr.statusCode === 400, 'AppError statusCode');
  assert(appErr.code === 'TEST_CODE', 'AppError code');
  assert(appErr.isOperational === true, 'AppError isOperational');
  assert(appErr instanceof Error, 'AppError extends Error');

  const badReq = new BadRequestError('invalid input');
  assert(badReq.statusCode === 400, 'BadRequestError status 400');
  assert(badReq.code === 'BAD_REQUEST', 'BadRequestError code');
  assert(badReq.message === 'invalid input', 'BadRequestError message');
  assert(badReq instanceof AppError, 'BadRequestError extends AppError');

  const auth = new UnauthorizedError();
  assert(auth.statusCode === 401, 'UnauthorizedError status 401');
  assert(auth.code === 'AUTH_REQUIRED', 'UnauthorizedError default code');
  assert(auth.message === 'Unauthorized', 'UnauthorizedError default message');

  const authCustom = new UnauthorizedError('token bad', 'TOKEN_INVALID');
  assert(authCustom.code === 'TOKEN_INVALID', 'UnauthorizedError custom code');

  const forbidden = new ForbiddenError();
  assert(forbidden.statusCode === 403, 'ForbiddenError status 403');

  const notFound = new NotFoundError('User');
  assert(notFound.statusCode === 404, 'NotFoundError status 404');
  assert(notFound.message === 'User not found', 'NotFoundError message includes resource');

  const conflict = new ConflictError();
  assert(conflict.statusCode === 409, 'ConflictError status 409');

  const validation = new ValidationError('bad', [{ field: 'email' }]);
  assert(validation.statusCode === 422, 'ValidationError status 422');
  assert(validation.details !== undefined, 'ValidationError has details');

  const rateLimit = new TooManyRequestsError();
  assert(rateLimit.statusCode === 429, 'TooManyRequestsError status 429');

  const fileLarge = new FileTooLargeError('10MB');
  assert(fileLarge.statusCode === 413, 'FileTooLargeError status 413');
  assert(fileLarge.message.includes('10MB'), 'FileTooLargeError includes size');

  const fileType = new InvalidFileTypeError(['.pdf', '.docx']);
  assert(fileType.statusCode === 400, 'InvalidFileTypeError status 400');
  assert(fileType.message.includes('.pdf'), 'InvalidFileTypeError lists types');
}

// ─── JWT Auth ───

function testJwtAuth() {
  console.log('\n🔑 Testing JWT Auth');

  process.env.JWT_SECRET = 'test-secret-key';

  const payload = { userId: 1, email: 'test@test.com' };
  const token = generateToken(payload);

  assert(typeof token === 'string', 'generateToken returns string');
  assert(token.split('.').length === 3, 'Token has 3 parts (header.payload.signature)');

  const decoded = verifyToken(token);
  assert(decoded.userId === 1, 'verifyToken decodes userId');
  assert(decoded.email === 'test@test.com', 'verifyToken decodes email');

  try {
    verifyToken('invalid.token.here');
    assert(false, 'Invalid token should throw', 'No error');
  } catch {
    assert(true, 'Invalid token throws error');
  }

  const shortToken = jwt.sign(payload, 'test-secret-key', { expiresIn: -10 });
  try {
    verifyToken(shortToken);
    assert(false, 'Expired token should throw', 'No error');
  } catch {
    assert(true, 'Expired token throws error');
  }

  delete process.env.JWT_SECRET;
}

// ─── Validate Middleware ───

function testValidate() {
  console.log('\n✅ Testing Validate Middleware');

  const schema = z.object({
    name: z.string().min(1),
    email: z.string().email(),
    age: z.number().int().min(0),
  });

  const validReq = mockReq({ body: { name: 'Bhuwan', email: 'bhuwan@test.com', age: 25 } });
  const validRes = mockRes();
  const validNext = mockNext();

  validate(schema)(validReq, validRes, validNext);
  assert(validNext.called === true, 'Valid body calls next()');
  assert(validNext.arg === undefined, 'Valid body calls next() without error');
  assert((validReq as any).body.name === 'Bhuwan', 'Valid body parsed and attached');

  const invalidReq = mockReq({ body: { name: '', email: 'not-an-email', age: -5 } });
  const invalidRes = mockRes();
  const invalidNext = mockNext();

  validate(schema)(invalidReq, invalidRes, invalidNext);
  assert(invalidNext.called === true, 'Invalid body calls next()');
  assert(invalidNext.arg instanceof AppError, 'Invalid body passes AppError');
  assert((invalidNext.arg as any).statusCode === 422, 'Invalid body error is 422');
  assert((invalidNext.arg as any).details.length === 3, 'Reports all 3 field errors');

  const missingReq = mockReq({ body: undefined });
  const missingRes = mockRes();
  const missingNext = mockNext();

  validate(schema)(missingReq, missingRes, missingNext);
  assert(missingNext.called === true, 'Missing body calls next()');
  assert(missingNext.arg instanceof AppError, 'Missing body passes AppError');

  const querySchema = z.object({ page: z.string() });
  const queryReq = mockReq({ query: { page: '1' } });
  const queryRes = mockRes();
  const queryNext = mockNext();

  validate(querySchema, 'query')(queryReq, queryRes, queryNext);
  assert(queryNext.called === true, 'Query validation works');
}

// ─── Sanitize ───

function testSanitize() {
  console.log('\n🧹 Testing Sanitize Functions');

  assert(sanitizeString('<script>alert("xss")</script>') === 'scriptalert("xss")/script', 'Strips angle brackets');

  assert(sanitizeString('javascript:alert(1)') === 'alert(1)', 'Strips javascript: protocol');

  assert(sanitizeString('onclick=doSomething()') === 'doSomething()', 'Strips onclick handlers');

  assert(sanitizeString('  hello world  ') === 'hello world', 'Trims whitespace');

  assert(sanitizeString('normal text') === 'normal text', 'Passes clean text unchanged');

  const obj = sanitizeObject({ name: '<b>bold</b>', age: 25 });
  assert(obj.name === 'bbold/b', 'sanitizeObject sanitizes string values');
  assert(obj.age === 25, 'sanitizeObject preserves non-string values');
}

// ─── Error Handler ───

function testErrorHandler() {
  console.log('\n🛡️  Testing Error Handler');

  process.env.NODE_ENV = 'test';

  const appErr = new BadRequestError('bad data');
  const req = mockReq();
  const res1 = mockRes();
  errorHandler(appErr, req, res1, () => {});
  assert(res1.statusCode === 400, 'AppError: correct status code');
  assert((res1.body as any).success === false, 'AppError: success is false');
  assert((res1.body as any).error.code === 'BAD_REQUEST', 'AppError: correct code');
  assert((res1.body as any).error.message === 'bad data', 'AppError: correct message');

  const corsErr = new Error('Not allowed by CORS');
  const res2 = mockRes();
  errorHandler(corsErr, req, res2, () => {});
  assert(res2.statusCode === 403, 'CORS error: status 403');
  assert((res2.body as any).error.code === 'CORS_ERROR', 'CORS error: code CORS_ERROR');

  const unknownErr = new Error('something broke');
  const res3 = mockRes();
  errorHandler(unknownErr, req, res3, () => {});
  assert(res3.statusCode === 500, 'Unknown error: status 500');
  assert((res3.body as any).error.code === 'INTERNAL_ERROR', 'Unknown error: code INTERNAL_ERROR');

  process.env.NODE_ENV = 'production';
  const res4 = mockRes();
  errorHandler(unknownErr, req, res4, () => {});
  assert((res4.body as any).error.message === 'Internal server error', 'Prod: message hidden');
  assert((res4.body as any).error.stack === undefined, 'Prod: stack trace hidden');

  process.env.NODE_ENV = 'test';
}

// ─── Not Found Handler ───

function testNotFoundHandler() {
  console.log('\n🔍 Testing Not Found Handler');

  const req = mockReq({ method: 'POST', originalUrl: '/api/v1/unknown' });
  const res = mockRes();
  const next = mockNext();

  notFoundHandler(req, res, next);
  assert(next.called === true, 'Calls next()');
  assert(next.arg instanceof AppError, 'Passes AppError');
  assert((next.arg as any).statusCode === 404, 'Status 404');
  assert((next.arg as any).message.includes('/api/v1/unknown'), 'Message includes route');
}

// ─── File Config ───

function testFileConfig() {
  console.log('\n📁 Testing File Config');

  assert(ALLOWED_FILE_CONFIG.maxFileSize === 10 * 1024 * 1024, 'Max size is 10MB');
  assert(ALLOWED_FILE_CONFIG.maxFileSizeLabel === '10MB', 'Max size label is 10MB');
  assert(ALLOWED_FILE_CONFIG.allowedExtensions.includes('.pdf'), 'Allows PDF');
  assert(ALLOWED_FILE_CONFIG.allowedExtensions.includes('.docx'), 'Allows DOCX');
  assert(ALLOWED_FILE_CONFIG.allowedExtensions.includes('.jpg'), 'Allows JPG');
  assert(ALLOWED_FILE_CONFIG.allowedExtensions.includes('.png'), 'Allows PNG');
  assert(ALLOWED_FILE_CONFIG.allowedExtensions.includes('.webp'), 'Allows WebP');
  assert(ALLOWED_FILE_CONFIG.allowedExtensions.includes('.txt'), 'Allows TXT');
  assert(!ALLOWED_FILE_CONFIG.allowedExtensions.includes('.exe'), 'Blocks EXE');
  assert(!ALLOWED_FILE_CONFIG.allowedExtensions.includes('.sh'), 'Blocks SH');
  assert(!ALLOWED_FILE_CONFIG.allowedExtensions.includes('.bat'), 'Blocks BAT');
  assert(ALLOWED_FILE_CONFIG.allowedMimeTypes.includes('application/pdf'), 'MIME: PDF');
  assert(ALLOWED_FILE_CONFIG.allowedMimeTypes.includes('image/png'), 'MIME: PNG');
  assert(ALLOWED_FILE_CONFIG.allowedMimeTypes.includes('image/jpeg'), 'MIME: JPEG');
}

function printSummary() {
  console.log('\n' + '='.repeat(60));
  const passed = results.filter((r) => r.pass).length;
  const failed = results.filter((r) => !r.pass).length;
  console.log(`Results: ${passed} passed, ${failed} failed, ${results.length} total`);
  console.log('='.repeat(60));

  if (failed > 0) {
    console.log('\nFailed tests:');
    results.filter((r) => !r.pass).forEach((r) => {
      console.log(`  ❌ ${r.test}${r.detail ? ` — ${r.detail}` : ''}`);
    });
  }

  return failed === 0;
}

async function main() {
  console.log('🧪 Legisense Middleware Tests\n');

  testErrorClasses();
  testJwtAuth();
  testValidate();
  testSanitize();
  testErrorHandler();
  testNotFoundHandler();
  testFileConfig();

  const allPassed = printSummary();
  process.exit(allPassed ? 0 : 1);
}

main().catch((err) => {
  console.error('Test runner failed:', err);
  process.exit(1);
});
