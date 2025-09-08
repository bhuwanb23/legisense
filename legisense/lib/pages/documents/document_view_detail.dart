import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'document_display.dart';
import 'document_analysis.dart';
import 'components/components.dart';
import 'data/sample_documents.dart';
import '../../api/parsed_documents_repository.dart';

class DocumentViewDetail extends StatefulWidget {
  const DocumentViewDetail({super.key, required this.title, required this.meta, this.docId});

  final String title;
  final String meta;
  final String? docId;

  @override
  State<DocumentViewDetail> createState() => _DocumentViewDetailState();
}

class _DocumentViewDetailState extends State<DocumentViewDetail> {
  int _tabIndex = 0; // 0 = Text, 1 = Analysis

  @override
  Widget build(BuildContext context) {
    if (widget.docId != null && widget.docId!.startsWith('server-')) {
      final int id = int.parse(widget.docId!.split('-').last);
      final repo = ParsedDocumentsRepository(baseUrl: const String.fromEnvironment('LEGISENSE_API_BASE', defaultValue: 'http://10.0.2.2:8000'));
      return FutureBuilder<SampleDocument>(
        future: repo.fetchDocumentDetail(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Container(
              color: const Color(0xFFF8FAFC),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Container(
              color: const Color(0xFFF8FAFC),
              child: Center(child: Text('Failed to load document: ${snapshot.error}')),
            );
          }
          final current = snapshot.data;
          return _buildScaffold(current);
        },
      );
    }

    final SampleDocument? current = null;
    return _buildScaffold(current);
  }

  Widget _buildScaffold(SampleDocument? current) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Custom App Bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                    ),
                    Expanded(
                      child: Column(
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
                    ),
                  ],
                ),
                // Tabs
                DetailTabs(
                  index: _tabIndex,
                  onChange: (i) => setState(() => _tabIndex = i),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _tabIndex == 0
                ? DocumentDisplayPanel(document: current)
                : AnalysisPanel(document: current),
          ),
        ],
      ),
    );
  }
}


