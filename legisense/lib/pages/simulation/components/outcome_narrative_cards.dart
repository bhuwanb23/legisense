import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OutcomeNarrativeCards extends StatelessWidget {
  const OutcomeNarrativeCards({super.key, required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Generated Outcomes', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...items.map((t) => _card(t)),
      ],
    );
  }

  Widget _card(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: const Color(0xFF000000).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155))),
    );
  }
}


