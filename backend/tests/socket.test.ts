import { describe, it, before, after, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import http from 'http';
import express from 'express';
import { Server as SocketServer } from 'socket.io';
import { io as ioc } from 'socket.io-client';
import { initSocketIO, closeSocketIO, emitToUser, emitToDocument, getIO } from '../src/services/socketService';
import { generateToken } from '../src/middleware/auth';
import { initDatabase, closeDatabase } from '../src/config/database';

let httpServer: http.Server;
let io: SocketServer;
let port: number;

process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-for-jwt';

const userId = 999;
const token = generateToken({ userId, email: 'socket-test@test.com' });

function closeSocket(socket: ReturnType<typeof ioc>): Promise<void> {
  return new Promise((resolve) => {
    socket.on('disconnect', () => resolve());
    socket.close();
    setTimeout(resolve, 500);
  });
}

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

describe('Socket.io', () => {
  describe('Authentication', () => {
    it('rejects connection without token', async () => {
      const socket = ioc(`http://localhost:${port}`, { transports: ['websocket'] });
      const err = await new Promise<string>((resolve) => {
        socket.on('connect_error', (e) => resolve(e.message));
      });
      await closeSocket(socket);
      assert.equal(err, 'Authentication required');
    });

    it('rejects connection with invalid token', async () => {
      const socket = ioc(`http://localhost:${port}`, {
        transports: ['websocket'],
        auth: { token: 'invalid-token' },
      });
      const err = await new Promise<string>((resolve) => {
        socket.on('connect_error', (e) => resolve(e.message));
      });
      await closeSocket(socket);
      assert.ok(err.length > 0);
    });

    it('accepts connection with valid token', async () => {
      const socket = await connectSocket();
      assert.ok(socket.connected);
      await closeSocket(socket);
    });
  });

  describe('Document Rooms', () => {
    it('joins user room automatically', async () => {
      const socket = await connectSocket();

      let received: any = null;
      socket.on('user:test', (data: any) => { received = data; });

      emitToUser(userId, 'user:test', { msg: 'hello user' });
      await new Promise((r) => setTimeout(r, 200));
      assert.deepEqual(received, { msg: 'hello user' });
      await closeSocket(socket);
    });

    it('subscribe:document joins document room', async () => {
      const socket = await connectSocket();

      socket.emit('subscribe:document', 42);
      await new Promise((r) => setTimeout(r, 100));

      let received: any = null;
      socket.on('doc:test', (data: any) => { received = data; });

      emitToDocument(42, 'doc:test', { msg: 'hello doc' });
      await new Promise((r) => setTimeout(r, 200));
      assert.deepEqual(received, { msg: 'hello doc' });
      await closeSocket(socket);
    });

    it('unsubscribe:document leaves document room', async () => {
      const socket = await connectSocket();

      socket.emit('subscribe:document', 99);

      let received: any = 'nothing';
      socket.on('doc:test2', (data: any) => { received = data; });

      socket.emit('unsubscribe:document', 99);
      await new Promise((r) => setTimeout(r, 100));

      emitToDocument(99, 'doc:test2', { msg: 'should not arrive' });
      await new Promise((r) => setTimeout(r, 200));
      assert.equal(received, 'nothing');
      await closeSocket(socket);
    });

    it('does not receive events for other documents', async () => {
      const socket = await connectSocket();

      socket.emit('subscribe:document', 1);
      await new Promise((r) => setTimeout(r, 100));

      let received: any = 'nothing';
      socket.on('doc:test3', (data: any) => { received = data; });

      emitToDocument(2, 'doc:test3', { msg: 'should not arrive' });
      await new Promise((r) => setTimeout(r, 200));
      assert.equal(received, 'nothing');
      await closeSocket(socket);
    });
  });

  describe('User isolation', () => {
    it('user A does not receive user B events', async () => {
      const userIdB = 888;
      const tokenB = generateToken({ userId: userIdB, email: 'b@test.com' });

      const socketA = ioc(`http://localhost:${port}`, {
        transports: ['websocket'],
        auth: { token },
      });
      const socketB = ioc(`http://localhost:${port}`, {
        transports: ['websocket'],
        auth: { token: tokenB },
      });
      await Promise.all([
        new Promise<void>((r) => socketA.on('connect', () => r())),
        new Promise<void>((r) => socketB.on('connect', () => r())),
      ]);

      let receivedA: any = 'nothing';
      socketA.on('isolated', (d: any) => { receivedA = d; });

      emitToUser(userIdB, 'isolated', { secret: 'for B only' });
      await new Promise((r) => setTimeout(r, 300));
      assert.equal(receivedA, 'nothing');

      await closeSocket(socketA);
      await closeSocket(socketB);
    });

    it('real event contract — job:update', async () => {
      const socket = await connectSocket();

      let received: any = null;
      socket.on('job:update', (data: any) => { received = data; });

      emitToUser(userId, 'job:update', { jobId: 'j_1', documentId: 1, status: 'processing' });
      await new Promise((r) => setTimeout(r, 200));
      assert.deepEqual(received, { jobId: 'j_1', documentId: 1, status: 'processing' });
      await closeSocket(socket);
    });
  });

  describe('getIO', () => {
    it('returns the io instance', () => {
      const instance = getIO();
      assert.ok(instance);
      assert.equal((instance as any).constructor.name, 'Server');
    });
  });
});
