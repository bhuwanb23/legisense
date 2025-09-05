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
                const AnalysisCard(
                  title: 'Key Clauses',
                  lines: [
                    'Termination clause detected',
                    'Non-compete clause present',
                    'Payment terms identified',
                  ],
                ),
                const SizedBox(height: 12),
                const AnalysisCard(
                  title: 'Risks & Alerts',
                  lines: [
                    'Ambiguous penalty wording',
                    'Missing jurisdiction detail',
                  ],
                ),
                const SizedBox(height: 12),
                const AnalysisCard(
                  title: 'Suggestions',
                  lines: [
                    'Clarify payment due dates',
                    'Add arbitration process',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

