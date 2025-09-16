import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'document_display.dart';
import 'document_analysis.dart';
import 'components/components.dart';
import 'data/sample_documents.dart';
import '../../api/parsed_documents_repository.dart';
import '../../components/bottom_nav_bar.dart';
import '../../main.dart';

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
  final int _currentPageIndex = 1; // Documents page index

  void _onPageChanged(int index) {
    if (index == _currentPageIndex) return;
    // Switch the root tab and pop back to the root so the persistent navbar remains
    navigateToPage(index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.docId != null && widget.docId!.startsWith('server-')) {
      final int id = int.parse(widget.docId!.split('-').last);
      final repo = ParsedDocumentsRepository(baseUrl: ApiConfig.baseUrl);
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load document',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please check your internet connection and ensure the server is running.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
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
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentPageIndex,
        onTap: _onPageChanged,
      ),
    );
  }
}


