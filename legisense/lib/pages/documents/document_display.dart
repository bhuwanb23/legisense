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
                  child: (document == null || document!.textBlocks.isEmpty)
                      ? Center(
                          child: Text(
                            'Select a document to preview',
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
                          ),
                        )
                      : ListView.builder(
                          itemCount: document!.textBlocks.length,
                          itemBuilder: (context, index) {
                            final pageText = document!.textBlocks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DocPageCard(
                                title: 'Page ${index + 1}',
                                paragraphs: [pageText],
                                sections: const [],
                              ),
                            );
                          },
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

