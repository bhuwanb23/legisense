export interface IcsDeadlineInput {
  id: number;
  title: string;
  description?: string | null;
  dueDate: string;
  consequenceIfMissed?: string | null;
  documentName?: string | null;
}

function escapeIcs(text: string): string {
  return text
    .replace(/\\/g, '\\\\')
    .replace(/;/g, '\\;')
    .replace(/,/g, '\\,')
    .replace(/\r\n/g, '\\n')
    .replace(/\n/g, '\\n');
}

function toIcsDate(dateStr: string): string {
  const cleaned = dateStr.replace(/[^0-9]/g, '');
  if (cleaned.length >= 8) return cleaned.slice(0, 8);
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) {
    const now = new Date();
    return now.toISOString().slice(0, 10).replace(/-/g, '');
  }
  return d.toISOString().slice(0, 10).replace(/-/g, '');
}

function foldLine(line: string): string {
  if (line.length <= 75) return line;
  const parts: string[] = [];
  let remaining = line;
  parts.push(remaining.slice(0, 75));
  remaining = remaining.slice(75);
  while (remaining.length > 0) {
    parts.push(' ' + remaining.slice(0, 74));
    remaining = remaining.slice(74);
  }
  return parts.join('\r\n');
}

export function buildIcsCalendar(deadlines: IcsDeadlineInput[], calendarName = 'LegiSense Deadlines'): string {
  const now = new Date();
  const stamp = now.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}Z$/, 'Z');

  const lines: string[] = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//LegiSense//Deadlines//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    `X-WR-CALNAME:${escapeIcs(calendarName)}`,
  ];

  for (const d of deadlines) {
    const start = toIcsDate(d.dueDate);
    // all-day end is exclusive next day
    const startDate = new Date(`${start.slice(0, 4)}-${start.slice(4, 6)}-${start.slice(6, 8)}T12:00:00Z`);
    const endDate = new Date(startDate);
    endDate.setUTCDate(endDate.getUTCDate() + 1);
    const end = endDate.toISOString().slice(0, 10).replace(/-/g, '');

    const summary = d.documentName
      ? `${d.title} — ${d.documentName}`
      : d.title;

    const descParts = [
      d.description || '',
      d.consequenceIfMissed ? `Consequence if missed: ${d.consequenceIfMissed}` : '',
      d.documentName ? `Document: ${d.documentName}` : '',
    ].filter(Boolean);

    lines.push('BEGIN:VEVENT');
    lines.push(`UID:legisense-deadline-${d.id}@legisense`);
    lines.push(`DTSTAMP:${stamp}`);
    lines.push(`DTSTART;VALUE=DATE:${start}`);
    lines.push(`DTEND;VALUE=DATE:${end}`);
    lines.push(foldLine(`SUMMARY:${escapeIcs(summary)}`));
    if (descParts.length) {
      lines.push(foldLine(`DESCRIPTION:${escapeIcs(descParts.join('\\n'))}`));
    }
    lines.push('BEGIN:VALARM');
    lines.push('TRIGGER:-P2D');
    lines.push('ACTION:DISPLAY');
    lines.push(`DESCRIPTION:${escapeIcs(`Reminder: ${d.title}`)}`);
    lines.push('END:VALARM');
    lines.push('END:VEVENT');
  }

  lines.push('END:VCALENDAR');
  return lines.join('\r\n') + '\r\n';
}
