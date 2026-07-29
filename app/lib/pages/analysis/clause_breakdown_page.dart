import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analysis/risk_style.dart';
import '../../widgets/analysis/soft_card.dart';
import '../chat/chat_page.dart';
import 'risk_dashboard_page.dart';
import 'plain_language_page.dart';

enum _ClauseFilter { all, high, medium, low, missing }

/// Page 15 — Clause-by-clause breakdown.
class ClauseBreakdownPage extends StatefulWidget {
  const ClauseBreakdownPage({
    super.key,
    required this.result,
    this.initialFilter,
  });

  final AnalysisResult result;
  final AnalysisRiskLevel? initialFilter;

  @override
  State<ClauseBreakdownPage> createState() => _ClauseBreakdownPageState();
}

class _ClauseBreakdownPageState extends State<ClauseBreakdownPage> {
  late _ClauseFilter _filter = switch (widget.initialFilter) {
    AnalysisRiskLevel.high => _ClauseFilter.high,
    AnalysisRiskLevel.medium => _ClauseFilter.medium,
    AnalysisRiskLevel.low => _ClauseFilter.low,
    AnalysisRiskLevel.missing => _ClauseFilter.missing,
    null => _ClauseFilter.all,
  };
  final _search = TextEditingController();
  final _expanded = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AnalysisClause> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return widget.result.clauses.where((c) {
      final levelOk = switch (_filter) {
        _ClauseFilter.all => true,
        _ClauseFilter.high => c.risk == AnalysisRiskLevel.high,
        _ClauseFilter.medium => c.risk == AnalysisRiskLevel.medium,
        _ClauseFilter.low => c.risk == AnalysisRiskLevel.low,
        _ClauseFilter.missing => c.risk == AnalysisRiskLevel.missing,
      };
      if (!levelOk) return false;
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          c.originalText.toLowerCase().contains(q) ||
          c.plainEnglish.toLowerCase().contains(q);
    }).toList();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clauses = _filtered;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        foregroundColor: AppColors.primaryNavy,
        title: Text(
          'Clauses',
          style: GoogleFonts.epilogue(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RiskDashboardPage(result: widget.result),
                ),
              );
            },
            child: Text(
              'Risks',
              style: GoogleFonts.epilogue(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.epilogue(color: AppColors.primaryNavy),
              decoration: InputDecoration(
                hintText: 'Search clauses…',
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in _ClauseFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filterLabel(f)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.primaryNavy,
                      labelStyle: GoogleFonts.epilogue(
                        fontWeight: FontWeight.w600,
                        color: _filter == f
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
          const SizedBox(height: 8),
          Expanded(
            child: clauses.isEmpty
                ? Center(
                    child: Text(
                      'No clauses match.',
                      style: GoogleFonts.epilogue(color: AppColors.inkSoft),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: clauses.length,
                    itemBuilder: (context, index) {
                      final c = clauses[index];
                      final open = _expanded.contains(c.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SoftCard(
                          onTap: () {
                            setState(() {
                              if (open) {
                                _expanded.remove(c.id);
                              } else {
                                _expanded.add(c.id);
                              }
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Clause ${c.number} — ${c.title}',
                                      style: GoogleFonts.epilogue(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                  ),
                                  RiskChip(level: c.risk),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                c.originalText,
                                maxLines: open ? null : 3,
                                overflow: open
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: GoogleFonts.epilogue(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              if (open) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Plain English',
                                  style: GoogleFonts.epilogue(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c.plainEnglish,
                                  style: GoogleFonts.epilogue(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => PlainLanguagePage(
                                            result: widget.result,
                                            initialClauseId: c.id,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'See Plain English',
                                      style: GoogleFonts.epilogue(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _toast('Flagged for review (demo).'),
                                    child: Text(
                                      'Flag',
                                      style: GoogleFonts.epilogue(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              ChatPage(result: widget.result),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Discuss',
                                      style: GoogleFonts.epilogue(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
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
    );
  }

  String _filterLabel(_ClauseFilter f) => switch (f) {
        _ClauseFilter.all => 'All',
        _ClauseFilter.high => 'High Risk',
        _ClauseFilter.medium => 'Medium',
        _ClauseFilter.low => 'Low',
        _ClauseFilter.missing => 'Missing',
      };
}
