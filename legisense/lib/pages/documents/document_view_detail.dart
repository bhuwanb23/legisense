import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'document_display.dart';
import 'document_analysis.dart';
import 'components/components.dart';

class DocumentViewDetail extends StatefulWidget {
  const DocumentViewDetail({super.key, required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  State<DocumentViewDetail> createState() => _DocumentViewDetailState();
}

class _DocumentViewDetailState extends State<DocumentViewDetail> {
  int _tabIndex = 0; // 0 = Text, 1 = Analysis

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.inter(
                color: const Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.meta,
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: DetailTabs(
            index: _tabIndex,
            onChange: (i) => setState(() => _tabIndex = i),
          ),
        ),
      ),
      body: _tabIndex == 0
          ? const DocumentDisplayPanel()
          : const AnalysisPanel(),
    );
  }
}


