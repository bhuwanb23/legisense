import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsMetric extends StatelessWidget {
  const StatsMetric({super.key, required this.value, required this.label, required this.bgColor, required this.valueColor});

  final String value;
  final String label;
  final Color bgColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: valueColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}


