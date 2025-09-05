import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DocPageCard extends StatelessWidget {
  const DocPageCard({super.key, required this.title, required this.paragraphs, this.sections});

  final String title;
  final List<String> paragraphs;
  final List<Widget>? sections; // optional extra sections like lists

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
          ),
          const SizedBox(height: 12),
          ...paragraphs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  p,
                  style: GoogleFonts.inter(fontSize: 14, height: 1.7, color: const Color(0xFF374151)),
                ),
              )),
          if (sections != null) ...sections!,
        ],
      ),
    );
  }
}


