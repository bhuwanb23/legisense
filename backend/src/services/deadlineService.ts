import { getDb, persistNow } from '../config/database';
import { deadlines } from '../models';
import { sql } from 'drizzle-orm';
import type { AnalysisOutput } from '../schemas/analysisSchemas';

export type UrgencyBucket = 'overdue' | 'this_week' | 'this_month' | 'upcoming';

export function calculateDeadlineUrgency(dateStr: string): UrgencyBucket {
  if (!dateStr || dateStr.length < 8) return 'upcoming';
  const parsed = new Date(dateStr);
  if (isNaN(parsed.getTime())) return 'upcoming';

  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const diffMs = parsed.getTime() - startOfToday.getTime();
  const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return 'overdue';
  if (diffDays <= 7) return 'this_week';
  if (diffDays <= 30) return 'this_month';
  return 'upcoming';
}

function addMonths(date: Date, months: number): Date {
  const d = new Date(date);
  d.setMonth(d.getMonth() + months);
  return d;
}

function addYears(date: Date, years: number): Date {
  const d = new Date(date);
  d.setFullYear(d.getFullYear() + years);
  return d;
}

function toDateOnly(d: Date): string {
  return d.toISOString().slice(0, 10);
}

export function expandRecurringDates(
  startDateStr: string,
  recurrence: string,
  count = 12,
): string[] {
  const start = new Date(startDateStr);
  if (isNaN(start.getTime())) return [startDateStr];

  const dates: string[] = [];
  let current = start;
  for (let i = 0; i < count; i++) {
    dates.push(toDateOnly(current));
    if (recurrence === 'monthly') current = addMonths(current, 1);
    else if (recurrence === 'quarterly') current = addMonths(current, 3);
    else if (recurrence === 'yearly') current = addYears(current, 1);
    else break;
  }
  return dates;
}

export interface DeadlineInput {
  title: string;
  description?: string;
  dueDate: string;
  recurrence?: string;
  deadlineType?: string;
  partyResponsible?: string;
  consequenceIfMissed?: string;
  isRecurring?: boolean;
}

export function saveDeadlinesForDocument(
  documentId: number,
  userId: number,
  items: DeadlineInput[],
): void {
  const db = getDb();

  for (const item of items) {
    const recurrence = item.recurrence || 'one-time';
    const isRecurring = Boolean(item.isRecurring) || (recurrence !== 'one-time' && recurrence !== '');
    const urgency = calculateDeadlineUrgency(item.dueDate);

    db.insert(deadlines).values({
      documentId,
      userId,
      title: item.title,
      description: item.description || item.title,
      dueDate: item.dueDate,
      recurrence,
      urgencyLevel: urgency,
      deadlineType: item.deadlineType || 'other',
      partyResponsible: item.partyResponsible || null,
      consequenceIfMissed: item.consequenceIfMissed || null,
      isRecurring,
      parentId: null,
    }).run();

    if (!isRecurring) continue;

    // Only expand payment-like schedules — avoid flooding UI from weak model recurrence tags.
    const blob = `${item.title} ${item.description || ''}`.toLowerCase();
    if (!/\b(emi|rent|salary|installment|subscription|monthly payment)\b/.test(blob)) {
      continue;
    }

    const parentRows = db.select().from(deadlines).where(
      sql`${deadlines.documentId} = ${documentId} AND ${deadlines.userId} = ${userId} AND ${deadlines.title} = ${item.title} AND ${deadlines.dueDate} = ${item.dueDate}`
    ).all();
    const parent = parentRows[parentRows.length - 1];
    if (!parent) continue;

    const childDates = expandRecurringDates(item.dueDate, recurrence, 4).slice(1);
    for (const childDate of childDates) {
      db.insert(deadlines).values({
        documentId,
        userId,
        title: item.title,
        description: item.description || item.title,
        dueDate: childDate,
        recurrence,
        urgencyLevel: calculateDeadlineUrgency(childDate),
        deadlineType: item.deadlineType || 'other',
        partyResponsible: item.partyResponsible || null,
        consequenceIfMissed: item.consequenceIfMissed || null,
        isRecurring: true,
        parentId: parent.id,
      }).run();
    }
  }

  persistNow();
}

export function buildDeadlineInputsFromAnalysis(ai: AnalysisOutput): DeadlineInput[] {
  const items: DeadlineInput[] = [];

  const usableDate = (value: string | null | undefined) => {
    if (!value) return false;
    const v = String(value).trim();
    if (!v || v.toLowerCase() === 'unknown' || v.length < 8) return false;
    if (/^\d{4}-\d{2}-\d{2}/.test(v)) return !Number.isNaN(Date.parse(v.slice(0, 10)));
    return !Number.isNaN(Date.parse(v));
  };

  for (const d of ai.deadlines || []) {
    if (!usableDate(d.dueDate)) continue;
    items.push({
      title: d.title,
      description: d.description,
      dueDate: d.dueDate,
      recurrence: d.recurrence,
      deadlineType: d.deadlineType || 'other',
      partyResponsible: d.partyResponsible || undefined,
      consequenceIfMissed: d.consequenceIfMissed || undefined,
      isRecurring: Boolean(d.isRecurring) || d.recurrence !== 'one-time',
    });
  }

  for (const cd of ai.criticalDates || []) {
    if (!usableDate(cd.date)) continue;
    if (items.some((i) => i.title === cd.label && i.dueDate === cd.date)) continue;
    items.push({
      title: cd.label,
      description: cd.importance || cd.label,
      dueDate: cd.date,
      recurrence: 'one-time',
      deadlineType: 'milestone',
      isRecurring: false,
    });
  }

  return items;
}

export function computeDeadlineHealth(rows: Array<{ urgencyLevel: string | null; isCompleted: boolean | null; isDismissed: boolean | null }>) {
  const active = rows.filter((d) => !d.isDismissed);
  const overdue = active.filter((d) => !d.isCompleted && d.urgencyLevel === 'overdue').length;
  const completed = active.filter((d) => d.isCompleted).length;
  const upcoming = active.filter((d) => !d.isCompleted && d.urgencyLevel !== 'overdue').length;

  let status: 'poor' | 'fair' | 'good' = 'good';
  if (overdue >= 3 || (overdue > 0 && completed === 0)) status = 'poor';
  else if (overdue > 0) status = 'fair';

  return { overdue, completed, upcoming, total: active.length, status };
}
