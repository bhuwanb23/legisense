export function isSmtpConfigured(): boolean {
  return Boolean(process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS);
}

export async function sendReminderEmail(opts: {
  to: string;
  title: string;
  dueDate: string;
  daysUntil: number;
  documentName?: string;
  consequence?: string;
}): Promise<boolean> {
  if (!isSmtpConfigured() || !opts.to) return false;

  try {
    const nodemailer = await import('nodemailer');
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT || 587),
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });

    const when = opts.daysUntil === 0
      ? 'today'
      : opts.daysUntil < 0
        ? `${Math.abs(opts.daysUntil)} day(s) overdue`
        : `in ${opts.daysUntil} day(s)`;

    const subject = `Reminder: ${opts.title} ${opts.daysUntil <= 0 ? '(due ' + when + ')' : 'in ' + opts.daysUntil + ' days'}`;
    const text = [
      `Deadline: ${opts.title}`,
      `Due: ${opts.dueDate} (${when})`,
      opts.documentName ? `Document: ${opts.documentName}` : '',
      opts.consequence ? `If missed: ${opts.consequence}` : '',
      '',
      'Open LegiSense to review this deadline.',
    ].filter(Boolean).join('\n');

    await transporter.sendMail({
      from: process.env.SMTP_FROM || process.env.SMTP_USER,
      to: opts.to,
      subject,
      text,
      html: `<p><strong>Deadline:</strong> ${opts.title}</p>
<p><strong>Due:</strong> ${opts.dueDate} (${when})</p>
${opts.documentName ? `<p><strong>Document:</strong> ${opts.documentName}</p>` : ''}
${opts.consequence ? `<p><strong>If missed:</strong> ${opts.consequence}</p>` : ''}
<p>Open LegiSense to review this deadline.</p>`,
    });
    return true;
  } catch (err) {
    console.error('Email send failed:', err instanceof Error ? err.message : err);
    return false;
  }
}
