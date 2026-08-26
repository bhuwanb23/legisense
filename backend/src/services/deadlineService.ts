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

export async function saveDeadlinesForDocument(
  documentId: number,
  userId: number,
  items: DeadlineInput[],
): Promise<void> {
  const db = getDb();

  for (const item of items) {
    const recurrence = item.recurrence || 'one-time';
    const isRecurring = Boolean(item.isRecurring) || (recurrence !== 'one-time' && recurrence !== '');
    const urgency = calculateDeadlineUrgency(item.dueDate);

    await db.insert(deadlines).values({
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
    });

    if (!isRecurring) continue;

    // Only expand payment-like schedules — avoid flooding UI from weak model recurrence tags.
    const blob = `${item.title} ${item.description || ''}`.toLowerCase();
    if (!/\b(emi|rent|salary|installment|subscription|monthly payment)\b/.test(blob)) {
      continue;
    }

    const parentRows = await db.select().from(deadlines).where(
      sql`${deadlines.documentId} = ${documentId} AND ${deadlines.userId} = ${userId} AND ${deadlines.title} = ${item.title} AND ${deadlines.dueDate} = ${item.dueDate}`
    );
    const parent = parentRows[parentRows.length - 1];
    if (!parent) continue;

    const childDates = expandRecurringDates(item.dueDate, recurrence, 12).slice(1);
    for (const childDate of childDates) {
      await db.insert(deadlines).values({
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
      });
    }
  }

  persistNow();
}

export function buildDeadlineInputsFromAnalysis(
  ai: AnalysisOutput,
  extraText = '',
): DeadlineInput[] {
  const items: DeadlineInput[] = [];

  const usableDate = (value: string | null | undefined) => {
    if (!value) return false;
    const v = String(value).trim();
    if (!v || v.toLowerCase() === 'unknown' || v.length < 8) return false;
    if (/^\d{4}-\d{2}-\d{2}/.test(v)) return !Number.isNaN(Date.parse(v.slice(0, 10)));
    return !Number.isNaN(Date.parse(v));
  };

  const normalizeLabel = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  const similar = (a: string, b: string) => {
    const na = normalizeLabel(a);
    const nb = normalizeLabel(b);
    if (na === nb) return true;
    const startish = (t: string) => /start|commencement|begin/.test(t);
    const endish = (t: string) => /end|expir|terminat/.test(t);
    return (startish(na) && startish(nb)) || (endish(na) && endish(nb));
  };

  const pushUnique = (item: DeadlineInput) => {
    const date = item.dueDate.slice(0, 10);
    if (items.some((i) => i.dueDate.slice(0, 10) === date && similar(i.title, item.title))) return;
    items.push({ ...item, dueDate: date });
  };

  for (const d of ai.deadlines || []) {
    if (!usableDate(d.dueDate)) continue;
    pushUnique({
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
    pushUnique({
      title: cd.label,
      description: cd.importance || cd.label,
      dueDate: cd.date,
      recurrence: 'one-time',
      deadlineType: 'milestone',
      isRecurring: false,
    });
  }

  const blob = `${extraText}\n${JSON.stringify(ai.keyObligations || [])}\n${(ai.clauses || []).map((c) => `${c.clauseTitle} ${c.originalText}`).join('\n')}`;
  const startItem = items.find((i) => /start|commencement|begin/.test(normalizeLabel(i.title)));
  const startDate = startItem ? new Date(startItem.dueDate) : null;
  const endItem = items.find((i) => /end|expir/.test(normalizeLabel(i.title)));

  if (startDate && !Number.isNaN(startDate.getTime())) {
    const lockMatch = blob.match(/lock[\s-]*in[\s\S]{0,220}?(\d+|three|six|twelve)\s*(?:\([^)]+\))?\s*months?/i)
      || blob.match(/first\s+(three|3|six|6|twelve|12)(?:\s*\(\d+\))?\s+months/i);
    if (lockMatch && !items.some((i) => /lock/.test(normalizeLabel(i.title)))) {
      let months = Number(lockMatch[1]);
      if (!Number.isFinite(months)) {
        const word = String(lockMatch[1] || '').toLowerCase();
        months = word.includes('six') ? 6 : word.includes('twelve') ? 12 : 3;
      }
      const lockEnd = addMonths(startDate, months);
      pushUnique({
        title: 'Lock-in period ends',
        description: `Licensee lock-in of ${months} months from commencement.`,
        dueDate: toDateOnly(lockEnd),
        recurrence: 'one-time',
        deadlineType: 'notice',
        isRecurring: false,
      });
    }
  }

  if (endItem && usableDate(endItem.dueDate)) {
    const noticeMatch = blob.match(/(\d+|eleven|thirty|sixty|ninety)(?:\s*\(\d+\))?\s+months?['’]?\s+(written\s+)?notice/i)
      || blob.match(/(\d+)\s*\((eleven|thirty|sixty|ninety)\)\s+months?['’]?\s+(written\s+)?notice/i)
      || blob.match(/notice of\s+(\d+)\s+(days|months)/i);
    if (noticeMatch && !items.some((i) => /notice/.test(normalizeLabel(i.title)))) {
      const raw = String(noticeMatch[1] || '').toLowerCase();
      const monthsMap: Record<string, number> = { eleven: 11, thirty: 1, sixty: 2, ninety: 3 };
      const n = monthsMap[raw] || Number(raw);
      if (Number.isFinite(n) && n > 0) {
        const expiry = new Date(endItem.dueDate);
        const noticeDate = addMonths(expiry, -n);
        pushUnique({
          title: 'Notice window to terminate',
          description: `${n}-month notice required before term end.`,
          dueDate: toDateOnly(noticeDate),
          recurrence: 'one-time',
          deadlineType: 'notice',
          isRecurring: false,
        });
      }
    }
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
