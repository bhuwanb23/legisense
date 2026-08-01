import PDFDocument from 'pdfkit';
import { Document, Packer, Paragraph, TextRun, HeadingLevel } from 'docx';

export interface ExportData {
  documentTitle: string;
  riskScore: number;
  summary: string;
  clauses: Array<{
    title: string;
    plainEnglish: string;
    riskLevel: string;
  }>;
  deadlines: Array<{
    description: string;
    dueDate: string;
  }>;
}

export async function generatePdfBuffer(data: ExportData): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    const doc = new PDFDocument();

    doc.on('data', (chunk: Buffer) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    doc.fontSize(24).font('Helvetica-Bold').text(data.documentTitle, { align: 'center' });
    doc.moveDown();

    doc.fontSize(12).font('Helvetica-Bold').text('Risk Score:', { continued: true });
    doc.font('Helvetica').text(` ${data.riskScore.toFixed(1)}/100`);
    doc.moveDown();

    doc.fontSize(12).font('Helvetica-Bold').text('Summary:');
    doc.fontSize(11).font('Helvetica').text(data.summary, { align: 'left', width: 500 });
    doc.moveDown();

    doc.fontSize(14).font('Helvetica-Bold').text('Clauses Analysis');
    doc.moveDown(0.5);

    for (const clause of data.clauses) {
      doc.fontSize(11).font('Helvetica-Bold').text(clause.title);
      doc.fontSize(10).font('Helvetica').text(`Risk Level: ${clause.riskLevel}`);
      doc.fontSize(10).font('Helvetica').text(clause.plainEnglish, { align: 'left', width: 500 });
      doc.moveDown(0.5);
    }

    if (data.deadlines.length > 0) {
      doc.fontSize(14).font('Helvetica-Bold').text('Deadlines');
      doc.moveDown(0.5);

      for (const deadline of data.deadlines) {
        doc.fontSize(10).font('Helvetica').text(`• ${deadline.description} (Due: ${deadline.dueDate})`);
      }
    }

    doc.end();
  });
}

export async function generateDocxBuffer(data: ExportData): Promise<Buffer> {
  const clauses = data.clauses.map((clause) =>
    new Paragraph({
      children: [
        new TextRun({
          text: clause.title,
          bold: true,
          size: 22,
        }),
      ],
    }),
  );

  clauses.push(
    ...data.clauses.flatMap((clause) => [
      new Paragraph({
        children: [
          new TextRun({
            text: `Risk Level: ${clause.riskLevel}`,
            size: 20,
          }),
        ],
      }),
      new Paragraph({
        children: [
          new TextRun({
            text: clause.plainEnglish,
            size: 20,
          }),
        ],
      }),
      new Paragraph({ text: '' }),
    ]),
  );

  const deadlinesParagraphs =
    data.deadlines.length > 0
      ? [
          new Paragraph({
            children: [
              new TextRun({
                text: 'Deadlines',
                bold: true,
                size: 28,
              }),
            ],
            heading: HeadingLevel.HEADING_1,
          }),
          ...data.deadlines.map(
            (deadline) =>
              new Paragraph({
                children: [
                  new TextRun({
                    text: `• ${deadline.description} (Due: ${deadline.dueDate})`,
                    size: 20,
                  }),
                ],
              }),
          ),
        ]
      : [];

  const doc = new Document({
    sections: [
      {
        children: [
          new Paragraph({
            children: [
              new TextRun({
                text: data.documentTitle,
                bold: true,
                size: 48,
              }),
            ],
            alignment: 'center',
          }),
          new Paragraph({ text: '' }),
          new Paragraph({
            children: [
              new TextRun({
                text: 'Risk Score: ',
                bold: true,
              }),
              new TextRun({
                text: `${data.riskScore.toFixed(1)}/100`,
              }),
            ],
          }),
          new Paragraph({ text: '' }),
          new Paragraph({
            children: [
              new TextRun({
                text: 'Summary:',
                bold: true,
              }),
            ],
          }),
          new Paragraph({
            children: [
              new TextRun({
                text: data.summary,
                size: 20,
              }),
            ],
          }),
          new Paragraph({ text: '' }),
          new Paragraph({
            children: [
              new TextRun({
                text: 'Clauses Analysis',
                bold: true,
                size: 28,
              }),
            ],
            heading: HeadingLevel.HEADING_1,
          }),
          ...clauses,
          ...deadlinesParagraphs,
        ],
      },
    ],
  });

  return await Packer.toBuffer(doc);
}
