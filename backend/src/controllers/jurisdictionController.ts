import { Request, Response, NextFunction } from 'express';
import { getDb } from '../config/database';
import { jurisdictions } from '../models';
import { sql } from 'drizzle-orm';

export async function listCountries(_req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const db = getDb();
    const rows = db.select().from(jurisdictions).where(
      sql`${jurisdictions.stateCode} IS NULL`
    ).all();

    const countries = rows
      .map((r) => ({
        country_code: r.countryCode,
        country_name: r.countryName,
      }))
      .sort((a, b) => a.country_name.localeCompare(b.country_name));

    res.json({ success: true, data: { countries } });
  } catch (err) {
    next(err);
  }
}

export async function listStates(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const country = String(req.params.country || '').toUpperCase();
    const db = getDb();
    const rows = db.select().from(jurisdictions).where(
      sql`${jurisdictions.countryCode} = ${country} AND ${jurisdictions.stateCode} IS NOT NULL`
    ).all();

    const states = rows
      .map((r) => ({
        country_code: r.countryCode,
        state_code: r.stateCode,
        state_name: r.stateName,
      }))
      .sort((a, b) => (a.state_name || '').localeCompare(b.state_name || ''));

    res.json({ success: true, data: { country_code: country, states } });
  } catch (err) {
    next(err);
  }
}
