import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'document_display.dart';
import 'document_analysis.dart';
import 'components/components.dart';
import 'data/sample_documents.dart';
import '../../api/parsed_documents_repository.dart';
import '../../components/bottom_nav_bar.dart';
import '../home/home_page.dart';
import '../simulation/simulation_page.dart';
import '../profile/profile_page.dart';

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
  int _currentPageIndex = 1; // Documents page index

  void _onPageChanged(int index) {
    if (index == _currentPageIndex) return; // Don't navigate if already on this page
    
    setState(() {
      _currentPageIndex = index;
    });

    // Navigate to the selected page
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 1:
        // Already on documents page, just pop back to documents list
        Navigator.of(context).pop();
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SimulationPage()),
        );
        break;
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ProfilePage(onLogout: () {})),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.docId != null && widget.docId!.startsWith('server-')) {
      final int id = int.parse(widget.docId!.split('-').last);
      final repo = ParsedDocumentsRepository(baseUrl: const String.fromEnvironment('LEGISENSE_API_BASE', defaultValue: 'http://10.0.2.2:8000'));
      return FutureBuilder<SampleDocument>(
        future: repo.fetchDocumentDetail(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              backgroundColor: Color(0xFFF8FAFC),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: Center(child: Text('Failed to load document: ${snapshot.error}')),
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
          ? DocumentDisplayPanel(document: current)
          : AnalysisPanel(document: current),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentPageIndex,
        onTap: _onPageChanged,
      ),
    );
  }
}


