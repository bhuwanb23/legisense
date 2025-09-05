import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'components/components.dart';

class DocumentDisplayPanel extends StatelessWidget {
  const DocumentDisplayPanel({super.key});

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
                child: Center(
                  child: Text(
                    'Select a document to preview',
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
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

