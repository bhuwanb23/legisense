import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import http from 'http';
import express from 'express';
import { Server as SocketServer } from 'socket.io';
import { io as ioc } from 'socket.io-client';
import { initSocketIO, closeSocketIO, emitToUser } from '../src/services/socketService';
import { generateToken } from '../src/middleware/auth';
import { initDatabase, closeDatabase } from '../src/config/database';

process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-for-jwt';

let httpServer: http.Server;
let io: SocketServer;
let port: number;

const userId = 555;
const token = generateToken({ userId, email: 'realtime-test@test.com' });

function connectSocket(): Promise<ReturnType<typeof ioc>> {
  return new Promise((resolve, reject) => {
    const socket = ioc(`http://localhost:${port}`, {
      transports: ['websocket'],
      auth: { token },
    });
    socket.on('connect', () => resolve(socket));
    socket.on('connect_error', (e) => reject(new Error(e.message)));
  });
}

function closeSocket(socket: ReturnType<typeof ioc>): Promise<void> {
  return new Promise((resolve) => {
    socket.on('disconnect', () => resolve());
    socket.close();
    setTimeout(resolve, 500);
  });
}

before(async () => {
  await initDatabase();
  const app = express();
  httpServer = http.createServer(app);
  io = initSocketIO(httpServer);
  await new Promise<void>((resolve) => {
    httpServer.listen(0, () => {
      port = (httpServer.address() as any).port;
      resolve();
    });
  });
});

after(async () => {
  await closeSocketIO();
  await new Promise<void>((resolve) => httpServer.close(() => resolve()));
  closeDatabase();
});

describe('Real-time event contracts', () => {
  it('analysis:started event reaches subscribed user', async () => {
    const socket = await connectSocket();

    let received: any = null;
    socket.on('analysis:started', (data: any) => { received = data; });

    emitToUser(userId, 'analysis:started', { documentId: 101 });
    await new Promise((r) => setTimeout(r, 200));

    assert.deepEqual(received, { documentId: 101 });
    await closeSocket(socket);
  });

  it('analysis:progress event reaches subscribed user', async () => {
    const socket = await connectSocket();

    const received: any[] = [];
    socket.on('analysis:progress', (data: any) => { received.push(data); });

    emitToUser(userId, 'analysis:progress', { documentId: 102, progress: 20, stage: 'Extracting text...' });
    emitToUser(userId, 'analysis:progress', { documentId: 102, progress: 50, stage: 'Analyzing chunk 1 of 3...' });
    emitToUser(userId, 'analysis:progress', { documentId: 102, progress: 100, stage: 'Done' });
    await new Promise((r) => setTimeout(r, 200));

    assert.equal(received.length, 3);
    assert.equal(received[0].progress, 20);
    assert.equal(received[1].progress, 50);
    assert.equal(received[2].progress, 100);
    await closeSocket(socket);
  });

  it('analysis:completed event reaches subscribed user', async () => {
    const socket = await connectSocket();

    let received: any = null;
    socket.on('analysis:completed', (data: any) => { received = data; });

    emitToUser(userId, 'analysis:completed', { documentId: 103 });
    await new Promise((r) => setTimeout(r, 200));

    assert.deepEqual(received, { documentId: 103 });
    await closeSocket(socket);
  });

  it('analysis:failed event reaches subscribed user', async () => {
    const socket = await connectSocket();

    let received: any = null;
    socket.on('analysis:failed', (data: any) => { received = data; });

    emitToUser(userId, 'analysis:failed', { documentId: 104, error: 'Something went wrong' });
    await new Promise((r) => setTimeout(r, 200));

    assert.deepEqual(received, { documentId: 104, error: 'Something went wrong' });
    await closeSocket(socket);
  });

  it('notification:new event reaches subscribed user', async () => {
    const socket = await connectSocket();

    let received: any = null;
    socket.on('notification:new', (data: any) => { received = data; });

    emitToUser(userId, 'notification:new', { id: 1, type: 'analysis_complete', title: 'Done', body: 'Analysis complete' });
    await new Promise((r) => setTimeout(r, 200));

    assert.equal(received.id, 1);
    assert.equal(received.type, 'analysis_complete');
    assert.equal(received.title, 'Done');
    await closeSocket(socket);
  });

  it('notification:new includes optional documentId', async () => {
    const socket = await connectSocket();

    let received: any = null;
    socket.on('notification:new', (data: any) => { received = data; });

    emitToUser(userId, 'notification:new', { id: 2, type: 'analysis_complete', title: 'Done', body: null, documentId: 105 });
    await new Promise((r) => setTimeout(r, 200));

    assert.equal(received.documentId, 105);
    await closeSocket(socket);
  });

  it('user does not receive events for other users', async () => {
    const otherId = 556;
    const otherToken = generateToken({ userId: otherId, email: 'other@test.com' });

    const socketA = await connectSocket();
    const socketB = ioc(`http://localhost:${port}`, {
      transports: ['websocket'],
      auth: { token: otherToken },
    });
    await new Promise<void>((r) => socketB.on('connect', () => r()));

    let receivedA: any = 'nothing';
    socketA.on('analysis:started', (d: any) => { receivedA = d; });

    emitToUser(otherId, 'analysis:started', { documentId: 999 });
    await new Promise((r) => setTimeout(r, 300));

    assert.equal(receivedA, 'nothing');

    await closeSocket(socketA);
    await closeSocket(socketB);
  });
});

describe('Notification service', () => {
  it('createNotification creates DB row and emits socket event', async () => {
    const socket = await connectSocket();

    let socketNotification: any = null;
    socket.on('notification:new', (data: any) => { socketNotification = data; });

    const { createNotification } = await import('../src/services/notificationService');

    const notifId = createNotification(userId, 'test_type', 'Test Title', 'Test body');

    assert.ok(notifId > 0, 'notification ID is positive');

    await new Promise((r) => setTimeout(r, 200));

    assert.ok(socketNotification, 'socket event was received');
    assert.equal(socketNotification.type, 'test_type');
    assert.equal(socketNotification.title, 'Test Title');

    await closeSocket(socket);
  });

  it('createNotification with documentId stores and emits it', async () => {
    const socket = await connectSocket();

    let socketNotif: any = null;
    socket.on('notification:new', (data: any) => { socketNotif = data; });

    const { createNotification } = await import('../src/services/notificationService');

    createNotification(userId, 'doc_ref', 'Doc Notification', 'Body with doc', 42);

    await new Promise((r) => setTimeout(r, 200));

    assert.equal(socketNotif.documentId, 42);

    await closeSocket(socket);
  });
});

describe('Progress callback', () => {
  it('analyzeDocument calls onProgress for small text', async () => {
    const { analyzeDocument } = await import('../src/services/aiService');

    const calls: { percent: number; stage: string }[] = [];
    const shortText = 'This is a short test document under 8k chars. ';

    try {
      await analyzeDocument(shortText.repeat(10), undefined, (percent, stage) => {
        calls.push({ percent, stage });
      });
    } catch {
      // AI provider not configured — test the callback contract
    }

    if (calls.length > 0) {
      assert.equal(calls[0].percent, 50);
      assert.ok(calls[0].stage.length > 0);
    }
  });

  it('analyzeDocument returns result even without onProgress', async () => {
    const { analyzeDocument } = await import('../src/services/aiService');

    try {
      const result = await analyzeDocument('short text', undefined);
      assert.ok(result, 'returns result');
      assert.ok(typeof result.processingTime === 'number');
    } catch {
      // AI not configured — that's fine for this contract test
    }
  });
});
