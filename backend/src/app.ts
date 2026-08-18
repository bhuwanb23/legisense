import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import {
  corsMiddleware,
  requestLogger,
  rateLimiter,
  errorHandler,
  notFoundHandler,
} from './middleware';
import documentRoutes from './routes/documentRoutes';
import authRoutes from './routes/authRoutes';
import userRoutes from './routes/userRoutes';
import analysisRoutes from './routes/analysisRoutes';
import chatRoutes from './routes/chatRoutes';
import deadlineRoutes from './routes/deadlineRoutes';
import notificationRoutes from './routes/notificationRoutes';
import jurisdictionRoutes from './routes/jurisdictionRoutes';
import languageRoutes from './routes/languageRoutes';
import featureRoutes from './routes/featureRoutes';
import v1Routes from './routes/v1Routes';
import helmet from 'helmet';
import path from 'path';

const app = express();

if (!process.env.JWT_SECRET) {
  console.warn('WARNING: JWT_SECRET is not set. Using insecure default. Set JWT_SECRET in .env');
}

app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
  contentSecurityPolicy: false,
}));
app.use(corsMiddleware);
app.use(requestLogger);
app.use(rateLimiter);
app.use(express.json());

app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'legisense-backend',
    timestamp: new Date().toISOString(),
  });
});

app.use('/api/documents', documentRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/analysis', analysisRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/deadlines', deadlineRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/jurisdictions', jurisdictionRoutes);
app.use('/api/languages', languageRoutes);
app.use('/api', featureRoutes);
app.use('/api/v1', v1Routes);

app.use(notFoundHandler);
app.use(errorHandler);

export default app;
