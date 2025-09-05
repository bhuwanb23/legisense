import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'components/components.dart';
import 'data/sample_documents.dart';

class DocumentDisplayPanel extends StatelessWidget {
  const DocumentDisplayPanel({super.key, this.document});

  final SampleDocument? document;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          const ViewerToolbar(),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Placeholder viewer content
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF9FAFB), Color(0xFFFFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: (document ?? kSampleDocuments.first).textBlocks.isEmpty
                      ? Center(
                          child: Text(
                            'Select a document to preview',
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
                          ),
                        )
                      : ListView(
                          children: [
                            DocPageCard(
                              title: 'Financial Report Q3 2024',
                              paragraphs: [
                                'This quarterly financial report presents a comprehensive overview of our company\'s performance during the third quarter of 2024. The document includes detailed analysis of revenue streams, expenditure patterns, and strategic initiatives that have shaped our financial landscape.',
                                'Key highlights include a 15% increase in revenue compared to the previous quarter, driven primarily by our digital transformation initiatives and expanded market presence in emerging sectors.',
                              ],
                              sections: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Revenue Breakdown', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1F2937))),
                                      const SizedBox(height: 8),
                                      Text('• Product Sales: \$2.4M (60%)\n• Services: \$1.2M (30%)\n• Licensing: \$400K (10%)', style: GoogleFonts.inter(fontSize: 13, height: 1.6, color: const Color(0xFF374151))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DocPageCard(
                              title: 'Market Analysis',
                              paragraphs: [
                                'Our market position has strengthened significantly, with increased brand recognition and customer satisfaction scores reaching an all-time high of 94%. The competitive landscape analysis reveals opportunities for further expansion.',
                              ],
                              sections: const [
                                SizedBox(height: 8),
                                _StatsGrid(),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: StatsMetric(
            value: '94%',
            label: 'Customer Satisfaction',
            bgColor: Color(0xFFEFF6FF),
            valueColor: Color(0xFF3B82F6),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatsMetric(
            value: '+15%',
            label: 'Revenue Growth',
            bgColor: Color(0xFFF0FDF4),
            valueColor: Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }
}

