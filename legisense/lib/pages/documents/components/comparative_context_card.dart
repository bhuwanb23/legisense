import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ComparativeContextCard extends StatelessWidget {
  const ComparativeContextCard({
    super.key,
    required this.label,
    required this.standard,
    required this.contract,
    required this.assessment,
  });

  final String label; // e.g., Notice Period
  final String standard; // e.g., 60 days
  final String contract; // e.g., 15 days
  final String assessment; // e.g., Risky

  @override
  Widget build(BuildContext context) {
    final isRisky = assessment.toLowerCase().contains('risk');
    final color = isRisky ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Assessment pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: _assessmentPill(color)),
            ],
          ),
          const SizedBox(height: 8),
          // Metrics row with equal columns and centered compare icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _metric('Standard', standard, alignRight: false)),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(Icons.compare_arrows, color: Color(0xFF64748B), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: _metric('Contract', contract, alignRight: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assessmentPill(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        assessment,
        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _metric(String label, String value, {bool alignRight = false}) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }
}


