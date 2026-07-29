import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import { verifyToken } from '../middleware/auth';

let io: Server | null = null;

export interface ServerToClientEvents {
  'job:update': (data: { jobId: string; documentId: number; status: string }) => void;
  'analysis:started': (data: { documentId: number }) => void;
  'analysis:progress': (data: { documentId: number; progress: number; stage: string }) => void;
  'analysis:completed': (data: { documentId: number }) => void;
  'analysis:failed': (data: { documentId: number; error: string }) => void;
  'notification:new': (data: { id: number; type: string; title: string; body: string | null; documentId?: number }) => void;
  'ocr:started': (data: { documentId: number }) => void;
  'ocr:progress': (data: { documentId: number; progress: number; stage: string }) => void;
  'ocr:completed': (data: {
    documentId: number;
    textLength: number;
    confidence: number;
    method: 'tesseract' | 'mistral';
    warnings?: Array<{ type: string; message: string }>;
    rotation?: number;
  }) => void;
  'ocr:failed': (data: { documentId: number; error: string }) => void;
  'error': (data: { message: string }) => void;
}

export interface ClientToServerEvents {
  'subscribe:document': (documentId: number) => void;
  'unsubscribe:document': (documentId: number) => void;
}

export function initSocketIO(httpServer: HttpServer): Server {
  io = new Server<ClientToServerEvents, ServerToClientEvents>(httpServer, {
    cors: {
      origin: process.env.CORS_ORIGIN?.split(',').map((s) => s.trim()) || '*',
      methods: ['GET', 'POST'],
    },
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;

    if (!token) {
      return next(new Error('Authentication required'));
    }

    try {
      const decoded = verifyToken(token);
      (socket as any).user = {
        userId: decoded.userId,
        email: decoded.email,
      };
      next();
    } catch {
      next(new Error('Invalid or expired token'));
    }
  });

  io.on('connection', (socket: Socket) => {
    const user = (socket as any).user as { userId: number; email: string };
    const userId = user.userId;

    socket.join(`user:${userId}`);
    console.log(`Socket connected: user ${userId} (socket ${socket.id})`);

    socket.on('subscribe:document', (documentId: number) => {
      socket.join(`document:${documentId}`);
    });

    socket.on('unsubscribe:document', (documentId: number) => {
      socket.leave(`document:${documentId}`);
    });

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: user ${userId} (socket ${socket.id})`);
    });
  });

  console.log('Socket.io initialized');
  return io;
}

export function emitToUser(userId: number, event: string, data: unknown): void {
  if (!io) {
    console.warn('Socket.io not initialized — skipping event emit');
    return;
  }
  io.to(`user:${userId}`).emit(event as any, data);
}

export function emitToDocument(documentId: number, event: string, data: unknown): void {
  if (!io) {
    return;
  }
  io.to(`document:${documentId}`).emit(event as any, data);
}

export function getIO(): Server | null {
  return io;
}

export async function closeSocketIO(): Promise<void> {
  if (io) {
    await io.close();
    io = null;
    console.log('Socket.io closed');
  }
}
