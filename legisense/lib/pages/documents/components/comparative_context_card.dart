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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: _metric('Standard', standard)),
                        const SizedBox(width: 12),
                        const Icon(Icons.compare_arrows, color: Color(0xFF64748B), size: 18),
                        const SizedBox(width: 12),
                        Flexible(child: _metric('Contract', contract)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Container(
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text(
                          assessment,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ],
    );
  }
}


