import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'components/components.dart';
import 'data/sample_documents.dart';

class AnalysisPanel extends StatelessWidget {
  const AnalysisPanel({super.key, this.document});

  final SampleDocument? document;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Analysis & Insights',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                TldrSummary(
                  text: (document ?? kSampleDocuments.first).tldr,
                ),
                const SizedBox(height: 12),
                const ListHeader(title: 'Clause Insights'),
                const SizedBox(height: 12),
                ...((document ?? kSampleDocuments.first).insights.map((i) {
                  final level = i.level == 'high'
                      ? RiskLevel.high
                      : i.level == 'medium'
                          ? RiskLevel.medium
                          : RiskLevel.low;
                  // derive bg/fg roughly by level
                  final Color bg = level == RiskLevel.high
                      ? const Color(0xFFFEE2E2)
                      : level == RiskLevel.medium
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFD1FAE5);
                  final Color fg = level == RiskLevel.high
                      ? const Color(0xFFDC2626)
                      : level == RiskLevel.medium
                          ? const Color(0xFFCA8A04)
                          : const Color(0xFF16A34A);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InsightRichCard(
                      icon: i.icon,
                      iconBgColor: bg,
                      iconColor: fg,
                      title: i.title,
                      description: i.description,
                      level: level,
                    ),
                  );
                })),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

