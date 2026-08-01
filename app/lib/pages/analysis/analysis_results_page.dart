import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../data/auth_constants.dart';
import '../../mappers/analysis_mapper.dart';
import '../../repositories/documents_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../utils/export_report.dart';
import '../../widgets/analysis/risk_style.dart';
import '../../widgets/home/app_page_header.dart';
import '../chat/chat_page.dart';
import '../deadlines/deadlines_page.dart';
import 'clause_breakdown_page.dart';
import 'counter_clauses_page.dart';
import 'document_summary_page.dart';
import 'flagged_clauses_page.dart';
import 'jurisdiction_flags_page.dart';
import 'missing_clauses_page.dart';
import 'plain_language_page.dart';
import 'risk_dashboard_page.dart';
import 'state_conflicts_page.dart';

/// Document analysis — analytics dashboard DNA (Sale / Product grammar).
class AnalysisResultsPage extends StatefulWidget {
  const AnalysisResultsPage({super.key, required this.result});

  final AnalysisResult result;

  @override
  State<AnalysisResultsPage> createState() => _AnalysisResultsPageState();
}

class _AnalysisResultsPageState extends State<AnalysisResultsPage> {
  int _mode = 0; // 0 = Overview, 1 = Clauses
  String _clauseFilter = 'all';
  late AnalysisResult _result;
  bool _translating = false;

  AnalysisResult get r => _result;

  static const _accent = AppColors.ink;
  static const _accentDeep = Color(0xFF2C2C2C);
  static const _green = Color(0xFF22C55E);
  static const _canvas = AppColors.bg;

  @override
  void initState() {
    super.initState();
    _result = widget.result;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _translate() async {
    final id = r.documentId;
    if (id == null || _translating) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Translate analysis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Summary and plain-language clauses will update in the language you pick.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.mute,
                  ),
                ),
              ),
              for (final lang in ProfileOptions.languages)
                ListTile(
                  title: Text(lang.label),
                  trailing: r.displayLanguage == lang.code
                      ? const Icon(Icons.check_rounded, color: AppColors.ink)
                      : null,
                  onTap: () => Navigator.pop(context, lang.code),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _translating = true);
    try {
      final snapshot = await DocumentsRepository().translate(
        id,
        targetLanguage: picked,
      );
      if (!mounted) return;
      final match = ProfileOptions.languages.where((l) => l.code == picked);
      final langLabel = match.isEmpty ? picked : match.first.label;
      setState(() {
        _result = AnalysisMapper.applyTranslation(_result, snapshot);
        _translating = false;
        _mode = 0;
      });
      _toast('Showing $langLabel translation');
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DocumentSummaryPage(result: _result),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _translating = false);
      _toast(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _translating = false);
      _toast(e.toString());
    }
  }

  List<AnalysisClause> get _filteredClauses {
    final list = r.clauses;
    return switch (_clauseFilter) {
      'high' => list.where((c) => c.risk == AnalysisRiskLevel.high).toList(),
      'medium' =>
        list.where((c) => c.risk == AnalysisRiskLevel.medium).toList(),
      'low' => list.where((c) => c.risk == AnalysisRiskLevel.low).toList(),
      'missing' =>
        list.where((c) => c.risk == AnalysisRiskLevel.missing).toList(),
      _ => list,
    };
  }

  int get _reviewPct {
    final total = r.clauses.length;
    if (total == 0) return 0;
    final reviewed = r.lowRiskCount + r.mediumRiskCount;
    return ((reviewed / total) * 100).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Analysis',
              subtitle: r.documentTitle,
              leading: AppHeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _ModeToggle(
                mode: _mode,
                onChanged: (v) => setState(() => _mode = v),
                accent: _accent,
                accentDeep: _accentDeep,
              ),
            ),
            Expanded(
              child: _mode == 0
                  ? _OverviewBody(
                      result: r,
                      reviewPct: _reviewPct,
                      accent: _accent,
                      accentDeep: _accentDeep,
                      green: _green,
                      translating: _translating,
                      onChat: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChatPage(result: r),
                          ),
                        );
                      },
                      onExport: () async {
                        final fmt = await pickExportFormat(context);
                        if (fmt == null || !mounted) return;
                        await exportAndShareReport(
                          context,
                          documentId: r.documentId,
                          title: r.documentTitle,
                          format: fmt,
                        );
                      },
                      onOpenSummary: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DocumentSummaryPage(result: r),
                          ),
                        );
                      },
                      onOpenRisk: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RiskDashboardPage(result: r),
                          ),
                        );
                      },
                      onOpenPlain: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlainLanguagePage(result: r),
                          ),
                        );
                      },
                      onOpenJurisdiction: r.documentId == null
                          ? null
                          : () => _push(
                                JurisdictionFlagsPage(
                                  documentId: r.documentId!,
                                ),
                              ),
                      onOpenStateConflicts: r.documentId == null
                          ? null
                          : () => _push(
                                StateConflictsPage(
                                  documentId: r.documentId!,
                                ),
                              ),
                      onOpenFlagged: r.documentId == null
                          ? null
                          : () => _push(
                                FlaggedClausesPage(
                                  documentId: r.documentId!,
                                ),
                              ),
                      onOpenMissing: r.documentId == null
                          ? null
                          : () => _push(
                                MissingClausesPage(
                                  documentId: r.documentId!,
                                ),
                              ),
                      onOpenCounter: r.documentId == null
                          ? null
                          : () => _push(
                                CounterClausesPage(
                                  documentId: r.documentId!,
                                ),
                              ),
                      onOpenDeadlines: r.documentId == null
                          ? null
                          : () => _push(
                                DeadlinesPage(documentId: r.documentId),
                              ),
                      onTranslate:
                          r.documentId == null ? null : _translate,
                    )
                  : _ClausesBody(
                      result: r,
                      filter: _clauseFilter,
                      clauses: _filteredClauses,
                      accent: _accent,
                      accentDeep: _accentDeep,
                      onFilter: (id) => setState(() => _clauseFilter = id),
                      onChat: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChatPage(result: r),
                          ),
                        );
                      },
                      onExport: () async {
                        final fmt = await pickExportFormat(context);
                        if (fmt == null || !mounted) return;
                        await exportAndShareReport(
                          context,
                          documentId: r.documentId,
                          title: r.documentTitle,
                          format: fmt,
                        );
                      },
                      onOpenAll: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ClauseBreakdownPage(result: r),
                          ),
                        );
                      },
                      onOpenPlain: (clauseId) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlainLanguagePage(
                              result: r,
                              initialClauseId: clauseId,
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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.onChanged,
    required this.accent,
    required this.accentDeep,
  });

  final int mode;
  final ValueChanged<int> onChanged;
  final Color accent;
  final Color accentDeep;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleHalf(
              label: 'Overview',
              selected: mode == 0,
              onTap: () => onChanged(0),
              accent: accent,
              accentDeep: accentDeep,
            ),
          ),
          Expanded(
            child: _ToggleHalf(
              label: 'Clauses',
              selected: mode == 1,
              onTap: () => onChanged(1),
              accent: accent,
              accentDeep: accentDeep,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleHalf extends StatelessWidget {
  const _ToggleHalf({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
    required this.accentDeep,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final Color accentDeep;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [accent, accentDeep])
              : null,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.mute,
          ),
        ),
      ),
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({
    required this.result,
    required this.reviewPct,
    required this.accent,
    required this.accentDeep,
    required this.green,
    required this.onOpenSummary,
    required this.onOpenRisk,
    required this.onOpenPlain,
    required this.onChat,
    required this.onExport,
    this.translating = false,
    this.onOpenJurisdiction,
    this.onOpenStateConflicts,
    this.onOpenFlagged,
    this.onOpenMissing,
    this.onOpenCounter,
    this.onOpenDeadlines,
    this.onTranslate,
  });

  final AnalysisResult result;
  final int reviewPct;
  final Color accent;
  final Color accentDeep;
  final Color green;
  final bool translating;
  final VoidCallback onOpenSummary;
  final VoidCallback onOpenRisk;
  final VoidCallback onOpenPlain;
  final VoidCallback onChat;
  final VoidCallback onExport;
  final VoidCallback? onOpenJurisdiction;
  final VoidCallback? onOpenStateConflicts;
  final VoidCallback? onOpenFlagged;
  final VoidCallback? onOpenMissing;
  final VoidCallback? onOpenCounter;
  final VoidCallback? onOpenDeadlines;
  final VoidCallback? onTranslate;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final langCode = r.displayLanguage;
    final langMatch = langCode == null
        ? null
        : ProfileOptions.languages.where((l) => l.code == langCode);
    final langLabel = (langMatch == null || langMatch.isEmpty)
        ? null
        : langMatch.first.label;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, AppInsets.shellBottom(context)),
      children: [
        _ActionRow(
          onChat: onChat,
          onExport: onExport,
        ),
        const SizedBox(height: 16),
        if (langLabel != null) ...[
          Material(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.translate_rounded,
                      size: 18, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Showing summary & plain language in $langLabel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Risk hero
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Risk score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: green,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      r.scoreBand == AnalysisRiskLevel.high
                          ? 'High'
                          : r.scoreBand == AnalysisRiskLevel.medium
                              ? 'Medium'
                              : 'Low',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${r.riskScore}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 4),
                    child: Text(
                      '/100',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
              if (r.biasSummary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  r.biasSummary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _StatTile(
              icon: Icons.warning_amber_rounded,
              iconColor: accentDeep,
              label: 'High risk',
              value: '${r.highRiskCount}',
              onTap: onOpenRisk,
            ),
            _StatTile(
              icon: Icons.article_outlined,
              iconColor: accent,
              label: 'Clauses',
              value: '${r.clauses.length}',
              onTap: onOpenSummary,
            ),
            _StatTile(
              icon: Icons.groups_outlined,
              iconColor: green,
              label: 'Parties',
              value: '${r.partyCount}',
              onTap: onOpenSummary,
            ),
            _StatTile(
              icon: Icons.translate_rounded,
              iconColor: const Color(0xFF1E88E5),
              label: 'Plain terms',
              value: '${r.clauses.length - r.missingCount}',
              onTap: onOpenPlain,
            ),
          ],
        ),
        if (r.riskCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          _WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk by category',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 140,
                  child: BarChart(
                    BarChartData(
                      maxY: () {
                        final maxCount = r.riskCategories
                            .map((c) => c.clauseIds.length)
                            .fold<int>(0, (a, b) => a > b ? a : b);
                        return (maxCount < 1 ? 1 : maxCount).toDouble() + 0.5;
                      }(),
                      barTouchData: const BarTouchData(enabled: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: AppColors.rule,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, _) {
                              if (v != v.roundToDouble()) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                '${v.toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: AppColors.mute,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= r.riskCategories.length) {
                                return const SizedBox.shrink();
                              }
                              final title = r.riskCategories[i].title;
                              final short = title.length > 8
                                  ? '${title.substring(0, 7)}…'
                                  : title;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  short,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppColors.mute,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        for (var i = 0; i < r.riskCategories.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: r.riskCategories[i].clauseIds.length
                                    .toDouble(),
                                width: 18,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                color: switch (r.riskCategories[i].level) {
                                  AnalysisRiskLevel.high => accentDeep,
                                  AnalysisRiskLevel.medium => accent,
                                  AnalysisRiskLevel.low => green,
                                  AnalysisRiskLevel.missing => AppColors.mute,
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Review progress
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Review progress',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${r.clauses.length} clauses · $reviewPct%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mute,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      Container(color: const Color(0xFFEEEEEE)),
                      FractionallySizedBox(
                        widthFactor: reviewPct / 100,
                        child: Container(color: accent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${r.highRiskCount + r.mediumRiskCount} flagged for review',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.mute,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onOpenSummary,
            child: Text(
              'Open full summary',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accentDeep,
              ),
            ),
          ),
        ),
        if (result.documentId != null) ...[
          const SizedBox(height: 4),
          _WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore analysis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                if (onOpenJurisdiction != null)
                  _NavTile(
                    icon: Icons.gavel_rounded,
                    label: 'Jurisdiction flags',
                    onTap: onOpenJurisdiction!,
                  ),
                if (onOpenStateConflicts != null)
                  _NavTile(
                    icon: Icons.map_outlined,
                    label: 'State conflicts',
                    onTap: onOpenStateConflicts!,
                  ),
                if (onOpenFlagged != null)
                  _NavTile(
                    icon: Icons.flag_outlined,
                    label: 'Flagged clauses',
                    onTap: onOpenFlagged!,
                  ),
                if (onOpenMissing != null)
                  _NavTile(
                    icon: Icons.playlist_add_check_rounded,
                    label: 'Missing clauses',
                    onTap: onOpenMissing!,
                  ),
                if (onOpenCounter != null)
                  _NavTile(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Counter clauses',
                    onTap: onOpenCounter!,
                  ),
                if (onOpenDeadlines != null)
                  _NavTile(
                    icon: Icons.event_outlined,
                    label: 'Deadlines',
                    onTap: onOpenDeadlines!,
                  ),
                if (onTranslate != null)
                  _NavTile(
                    icon: Icons.translate_rounded,
                    label: translating
                        ? 'Translating…'
                        : langLabel != null
                            ? 'Translate ($langLabel)'
                            : 'Translate',
                    onTap: translating ? () {} : onTranslate!,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      minLeadingWidth: 36,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.chip,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.ink),
      ),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          size: 20, color: AppColors.mute),
      onTap: onTap,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.mute,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClausesBody extends StatelessWidget {
  const _ClausesBody({
    required this.result,
    required this.filter,
    required this.clauses,
    required this.accent,
    required this.accentDeep,
    required this.onFilter,
    required this.onChat,
    required this.onExport,
    required this.onOpenAll,
    required this.onOpenPlain,
  });

  final AnalysisResult result;
  final String filter;
  final List<AnalysisClause> clauses;
  final Color accent;
  final Color accentDeep;
  final ValueChanged<String> onFilter;
  final VoidCallback onChat;
  final VoidCallback onExport;
  final VoidCallback onOpenAll;
  final ValueChanged<String> onOpenPlain;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, AppInsets.shellBottom(context)),
      children: [
        _ActionRow(
          onChat: onChat,
          onExport: onExport,
        ),
        const SizedBox(height: 16),
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Risk by category',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'This doc',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.mute,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 150,
                child: BarChart(
                  BarChartData(
                    maxY: (r.highRiskCount + r.mediumRiskCount + r.lowRiskCount)
                            .toDouble()
                            .clamp(4, 20) +
                        2,
                    barTouchData: const BarTouchData(enabled: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: AppColors.rule,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            const labels = ['High', 'Med', 'Low', 'Miss'];
                            final i = v.toInt();
                            if (i < 0 || i >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                labels[i],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mute,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      _bar(0, r.highRiskCount.toDouble(), AppColors.riskHigh),
                      _bar(1, r.mediumRiskCount.toDouble(), AppColors.riskMedium),
                      _bar(2, r.lowRiskCount.toDouble(), AppColors.riskLow),
                      _bar(3, r.missingCount.toDouble(), AppColors.riskMissing),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  _Legend(color: AppColors.riskHigh, label: 'High'),
                  _Legend(color: AppColors.riskMedium, label: 'Medium'),
                  _Legend(color: AppColors.riskLow, label: 'Low'),
                  _Legend(color: AppColors.riskMissing, label: 'Missing'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Clause list',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onOpenAll,
                    child: Text(
                      'See all',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: accentDeep,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final chip in const [
                      ('all', 'All'),
                      ('high', 'High'),
                      ('medium', 'Medium'),
                      ('low', 'Low'),
                      ('missing', 'Missing'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => onFilter(chip.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: filter == chip.$1
                                      ? accentDeep
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Text(
                              chip.$2,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: filter == chip.$1
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: filter == chip.$1
                                    ? AppColors.ink
                                    : AppColors.mute,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...clauses.take(8).map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => onOpenPlain(c.id),
                    borderRadius: BorderRadius.circular(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: RiskStyle.background(c.risk),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: 20,
                            color: RiskStyle.color(c.risk),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clause ${c.number} — ${c.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.categories.isNotEmpty
                                    ? c.categories.first
                                    : r.documentType,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.mute,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: RiskStyle.background(c.risk),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            RiskStyle.label(c.risk),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: RiskStyle.color(c.risk),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y <= 0 ? 0.15 : y,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          color: color,
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.mute,
          ),
        ),
      ],
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onChat,
    required this.onExport,
  });

  final VoidCallback onChat;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: onChat,
              child: Ink(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        color: Colors.white, size: 17),
                    const SizedBox(width: 8),
                    Text(
                      'Chat',
                      maxLines: 1,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _ActionChip(
            label: 'Export',
            icon: Icons.ios_share_rounded,
            onTap: onExport,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.rule),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.ink),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
