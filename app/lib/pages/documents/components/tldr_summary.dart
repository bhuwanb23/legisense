import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TldrSummary extends StatelessWidget {
  const TldrSummary({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'TL;DR Summary',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E3A8A), // blue-900
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF), // blue-50
            border: Border.all(color: const Color(0xFFDBEAFE)), // blue-100
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}


