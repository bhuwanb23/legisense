import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../data/dashboard_mock.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analysis/risk_style.dart';
import '../../widgets/analysis/soft_card.dart';
import '../analysis/analysis_results_page.dart';

enum _HistorySort { newest, riskiest, oldest }

/// Page 18 — Document history / library (Documents tab).
class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key, this.onOpenUpload});

  final VoidCallback? onOpenUpload;

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final _search = TextEditingController();
  String _filter = 'all';
  _HistorySort _sort = _HistorySort.newest;
  late final List<MockDocument> _docs =
      List<MockDocument>.from(DashboardMock.recentDocuments);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MockDocument> get _visible {
    var list = DashboardMock.historyFiltered(_filter);
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (d) =>
                d.title.toLowerCase().contains(q) ||
                d.typeLabel.toLowerCase().contains(q) ||
                d.relativeDate.toLowerCase().contains(q),
          )
          .toList();
    }
    list = List<MockDocument>.from(list);
    switch (_sort) {
      case _HistorySort.newest:
        list.sort((a, b) => a.daysAgo.compareTo(b.daysAgo));
      case _HistorySort.oldest:
        list.sort((a, b) => b.daysAgo.compareTo(a.daysAgo));
      case _HistorySort.riskiest:
        list.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    }
    // Prefer live deleted state from _docs ids
    final ids = _docs.map((d) => d.id).toSet();
    return list.where((d) => ids.contains(d.id)).toList();
  }

  void _openAnalysis(MockDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalysisResultsPage(
          result: AnalysisResult.fromMockDocument(doc),
        ),
      ),
    );
  }

  void _share(MockDocument doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share for “${doc.title}” comes with backend.'),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _delete(MockDocument doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete document?',
          style: GoogleFonts.epilogue(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove “${doc.title}” from your library? (Demo only — not permanent.)',
          style: GoogleFonts.epilogue(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.epilogue(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _docs.removeWhere((d) => d.id == doc.id));
    }
  }

  void _goUpload() {
    widget.onOpenUpload?.call();
  }

  @override
  Widget build(BuildContext context) {
    final docs = _visible;

    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Documents',
                      style: GoogleFonts.epilogue(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _goUpload,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: AppColors.cloud,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Upload',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.epilogue(color: AppColors.primaryNavy),
                decoration: InputDecoration(
                  hintText: 'Search by name, type, or date…',
                  hintStyle: GoogleFonts.epilogue(color: AppColors.inkSoft),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.cloud,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final chip in const [
                    ('all', 'All'),
                    ('lease', 'Lease'),
                    ('nda', 'NDA'),
                    ('employment', 'Employment'),
                    ('others', 'Others'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(chip.$2),
                        selected: _filter == chip.$1,
                        onSelected: (_) =>
                            setState(() => _filter = chip.$1),
                        selectedColor: AppColors.primaryNavy,
                        labelStyle: GoogleFonts.epilogue(
                          fontWeight: FontWeight.w600,
                          color: _filter == chip.$1
                              ? AppColors.cloud
                              : AppColors.primaryNavy,
                        ),
                        backgroundColor: AppColors.cloud,
                        side: const BorderSide(color: AppColors.borderMuted),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Row(
                children: [
                  Text(
                    'Sort',
                    style: GoogleFonts.epilogue(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<_HistorySort>(
                    value: _sort,
                    underline: const SizedBox.shrink(),
                    style: GoogleFonts.epilogue(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _HistorySort.newest,
                        child: Text('Newest'),
                      ),
                      DropdownMenuItem(
                        value: _HistorySort.riskiest,
                        child: Text('Riskiest'),
                      ),
                      DropdownMenuItem(
                        value: _HistorySort.oldest,
                        child: Text('Oldest'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _sort = v);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Text(
                        'No documents match.',
                        style: GoogleFonts.epilogue(color: AppColors.inkSoft),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final band = RiskStyle.bandForScore(doc.riskScore);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SoftCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      color: AppColors.primaryNavy,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        doc.title,
                                        style: GoogleFonts.epilogue(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryNavy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '📄 ${doc.typeLabel}',
                                        style: GoogleFonts.epilogue(
                                          fontSize: 13,
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: RiskStyle.background(band),
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.pill,
                                        ),
                                      ),
                                      child: Text(
                                        'Score: ${doc.riskScore}',
                                        style: GoogleFonts.epilogue(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: RiskStyle.color(band),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Analyzed: ${doc.relativeDate}',
                                  style: GoogleFonts.epilogue(
                                    fontSize: 12,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => _openAnalysis(doc),
                                      child: Text(
                                        'View',
                                        style: GoogleFonts.epilogue(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _share(doc),
                                      child: Text(
                                        'Share',
                                        style: GoogleFonts.epilogue(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _delete(doc),
                                      child: Text(
                                        'Delete',
                                        style: GoogleFonts.epilogue(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
