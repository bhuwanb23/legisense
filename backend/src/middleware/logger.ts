import { Request, Response, NextFunction } from 'express';

const COLORS: Record<string, string> = {
  GET: '\x1b[32m',
  POST: '\x1b[36m',
  PUT: '\x1b[33m',
  PATCH: '\x1b[33m',
  DELETE: '\x1b[31m',
  OPTIONS: '\x1b[90m',
  RESET: '\x1b[0m',
};

function colorize(method: string, text: string): string {
  const color = COLORS[method] || '';
  return color ? `${color}${text}${COLORS.RESET}` : text;
}

function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  return `${(ms / 1000).toFixed(2)}s`;
}

export function requestLogger(req: Request, res: Response, next: NextFunction): void {
  const start = Date.now();
  const timestamp = new Date().toISOString();

  res.on('finish', () => {
    const duration = Date.now() - start;
    const status = res.statusCode;
    const userId = req.user?.id || '-';
    const method = req.method;
    const path = req.originalUrl;

    const statusColor =
      status >= 500
        ? '\x1b[31m'
        : status >= 400
          ? '\x1b[33m'
          : status >= 300
            ? '\x1b[36m'
            : '\x1b[32m';

    const log = `[${timestamp}] ${colorize(method, method.padEnd(7))} ${path.padEnd(40)} ${statusColor}${status}\x1b[0m ${formatDuration(duration).padEnd(10)} user:${userId}`;

    if (status >= 500) {
      console.error(log);
    } else {
      console.log(log);
    }
  });

  next();
}
