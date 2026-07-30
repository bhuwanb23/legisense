import { Request, Response, NextFunction } from 'express';
import { SUPPORTED_LANGUAGES } from '../config/languages';

export async function listSupportedLanguages(_req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    res.json({
      success: true,
      data: { languages: SUPPORTED_LANGUAGES, total: SUPPORTED_LANGUAGES.length },
    });
  } catch (err) {
    next(err);
  }
}
