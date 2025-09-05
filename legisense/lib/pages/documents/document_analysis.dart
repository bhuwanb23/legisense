import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'components/components.dart';

class AnalysisPanel extends StatelessWidget {
  const AnalysisPanel({super.key});

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
                const TldrSummary(
                  text:
                      'This contract contains moderate risk clauses. Payment terms are standard with 30-day periods. Termination clause favors the vendor with limited client protections. Liability is capped but exclusions are broad.',
                ),
                const SizedBox(height: 12),
                const ListHeader(title: 'Clause Insights'),
                const SizedBox(height: 12),
                InsightRichCard(
                  icon: Icons.credit_card,
                  iconBgColor: const Color(0xFFD1FAE5),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Payment Terms',
                  description:
                      'Standard 30-day payment terms with 2% early payment discount. No unusual penalties or accelerated payment clauses.',
                  level: RiskLevel.low,
                ),
                const SizedBox(height: 12),
                InsightRichCard(
                  icon: Icons.meeting_room,
                  iconBgColor: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFCA8A04),
                  title: 'Termination Clause',
                  description:
                      'Vendor can terminate with 15-day notice while client requires 60-day notice. Imbalanced termination rights favor vendor.',
                  level: RiskLevel.medium,
                ),
                const SizedBox(height: 12),
                InsightRichCard(
                  icon: Icons.shield,
                  iconBgColor: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFDC2626),
                  title: 'Liability Limitations',
                  description:
                      'Broad liability exclusions with cap limited to 12 months fees. Consequential damages excluded entirely.',
                  level: RiskLevel.high,
                ),
                const SizedBox(height: 12),
                InsightRichCard(
                  icon: Icons.storage,
                  iconBgColor: const Color(0xFFD1FAE5),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Data Protection',
                  description:
                      'GDPR compliant data processing terms with clear data retention and deletion policies outlined.',
                  level: RiskLevel.low,
                ),
                const SizedBox(height: 12),
                InsightRichCard(
                  icon: Icons.lightbulb,
                  iconBgColor: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFCA8A04),
                  title: 'Intellectual Property',
                  description:
                      'Work-for-hire provisions unclear. Derivative works ownership may transfer to vendor after project completion.',
                  level: RiskLevel.medium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

