import cors from 'cors';

const isDev = process.env.NODE_ENV !== 'production';

const rawOrigins = process.env.CORS_ORIGIN || '';
const whitelist = rawOrigins
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

export const corsMiddleware = cors({
  origin: isDev
    ? true
    : (origin, callback) => {
        if (!origin || whitelist.includes(origin)) {
          callback(null, true);
        } else {
          callback(new Error('Not allowed by CORS'));
        }
      },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id'],
  maxAge: 86400,
});
