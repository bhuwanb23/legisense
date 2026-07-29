import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analysis/risk_style.dart';
import '../chat/chat_page.dart';
import 'clause_breakdown_page.dart';
import 'document_summary_page.dart';
import 'plain_language_page.dart';
import 'risk_dashboard_page.dart';

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

  AnalysisResult get r => widget.result;

  static const _orange = Color(0xFFFF7A1A);
  static const _orangeDeep = Color(0xFFFF4D00);
  static const _green = Color(0xFF22C55E);
  static const _canvas = Color(0xFFF4F4F5);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.ink,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analysis',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          r.documentTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.mute,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _ModeToggle(
                mode: _mode,
                onChanged: (v) => setState(() => _mode = v),
                orange: _orange,
                orangeDeep: _orangeDeep,
              ),
            ),
            Expanded(
              child: _mode == 0
                  ? _OverviewBody(
                      result: r,
                      reviewPct: _reviewPct,
                      orange: _orange,
                      orangeDeep: _orangeDeep,
                      green: _green,
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
                    )
                  : _ClausesBody(
                      result: r,
                      filter: _clauseFilter,
                      clauses: _filteredClauses,
                      orange: _orange,
                      orangeDeep: _orangeDeep,
                      onFilter: (id) => setState(() => _clauseFilter = id),
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
            _BottomActions(
              onChat: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatPage(result: r),
                  ),
                );
              },
              onExport: () => _toast('Export report comes with backend.'),
              onCompare: () => _toast('Version compare comes later.'),
              orange: _orange,
              orangeDeep: _orangeDeep,
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
    required this.orange,
    required this.orangeDeep,
  });

  final int mode;
  final ValueChanged<int> onChanged;
  final Color orange;
  final Color orangeDeep;

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
              orange: orange,
              orangeDeep: orangeDeep,
            ),
          ),
          Expanded(
            child: _ToggleHalf(
              label: 'Clauses',
              selected: mode == 1,
              onTap: () => onChanged(1),
              orange: orange,
              orangeDeep: orangeDeep,
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
    required this.orange,
    required this.orangeDeep,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color orange;
  final Color orangeDeep;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [orange, orangeDeep])
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
    required this.orange,
    required this.orangeDeep,
    required this.green,
    required this.onOpenSummary,
    required this.onOpenRisk,
    required this.onOpenPlain,
  });

  final AnalysisResult result;
  final int reviewPct;
  final Color orange;
  final Color orangeDeep;
  final Color green;
  final VoidCallback onOpenSummary;
  final VoidCallback onOpenRisk;
  final VoidCallback onOpenPlain;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        // Hero risk card
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [orange, orangeDeep],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: orange.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Risk score',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${r.riskScore}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 6),
                    child: Text(
                      '/ 100',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: green,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      r.scoreBand == AnalysisRiskLevel.high
                          ? 'High exposure'
                          : r.scoreBand == AnalysisRiskLevel.medium
                              ? 'Needs review'
                              : 'Manageable',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                r.biasSummary,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 40),
                          FlSpot(1, 55),
                          FlSpot(2, 48),
                          FlSpot(3, 62),
                          FlSpot(4, 70),
                          FlSpot(5, 72),
                        ],
                        isCurved: true,
                        color: Colors.white,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 2x2 stats
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
              iconBg: const Color(0xFFFFE8E0),
              iconColor: orangeDeep,
              label: 'High risk',
              value: '${r.highRiskCount}',
              delta: '+${r.highRiskCount}',
              green: green,
              onTap: onOpenRisk,
            ),
            _StatTile(
              icon: Icons.article_outlined,
              iconBg: const Color(0xFFFFF0E0),
              iconColor: orange,
              label: 'Clauses',
              value: '${r.clauses.length}',
              delta: '+${r.clauses.length}',
              green: green,
              onTap: onOpenSummary,
            ),
            _StatTile(
              icon: Icons.groups_outlined,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: green,
              label: 'Parties',
              value: '${r.partyCount}',
              delta: '+${r.partyCount}',
              green: green,
              onTap: onOpenSummary,
            ),
            _StatTile(
              icon: Icons.translate_rounded,
              iconBg: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1E88E5),
              label: 'Plain terms',
              value: '${r.clauses.length - r.missingCount}',
              delta: 'Ready',
              green: green,
              onTap: onOpenPlain,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Risk trend chart card
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Risk trend',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _canvasInner,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: AppColors.mute),
                        const SizedBox(width: 6),
                        Text(
                          'Sections',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 8,
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
                          interval: 2,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppColors.mute,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            const labels = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6'];
                            final i = v.toInt();
                            if (i < 0 || i >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                labels[i],
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
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 2),
                          FlSpot(1, 3.2),
                          FlSpot(2, 2.6),
                          FlSpot(3, 4.5),
                          FlSpot(4, 5.8),
                          FlSpot(5, 6.4),
                        ],
                        isCurved: true,
                        gradient: LinearGradient(colors: [orange, orangeDeep]),
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                            radius: 3.5,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: orangeDeep,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              orange.withValues(alpha: 0.28),
                              orange.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Review progress
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review progress',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mute,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${r.clauses.length} clauses',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '$reviewPct%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: orangeDeep,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${r.highRiskCount + r.mediumRiskCount} flagged',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mute,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Container(color: const Color(0xFFEEEEEE)),
                      FractionallySizedBox(
                        widthFactor: reviewPct / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [orange, orangeDeep],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onOpenSummary,
          child: Text(
            'Open full summary',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: orangeDeep,
            ),
          ),
        ),
      ],
    );
  }
}

const _canvasInner = Color(0xFFF4F4F5);

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.delta,
    required this.green,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String delta;
  final Color green;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const Spacer(),
                  Text(
                    delta,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: green,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.mute,
                ),
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
    required this.orange,
    required this.orangeDeep,
    required this.onFilter,
    required this.onOpenAll,
    required this.onOpenPlain,
  });

  final AnalysisResult result;
  final String filter;
  final List<AnalysisClause> clauses;
  final Color orange;
  final Color orangeDeep;
  final ValueChanged<String> onFilter;
  final VoidCallback onOpenAll;
  final ValueChanged<String> onOpenPlain;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
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
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    maxY: (r.highRiskCount + r.mediumRiskCount + r.lowRiskCount)
                            .toDouble()
                            .clamp(4, 20) +
                        2,
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
                        color: orangeDeep,
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
                                      ? orangeDeep
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
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => onOpenPlain(c.id),
                    borderRadius: BorderRadius.circular(14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: RiskStyle.background(c.risk),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.description_outlined,
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.onChat,
    required this.onExport,
    required this.onCompare,
    required this.orange,
    required this.orangeDeep,
  });

  final VoidCallback onChat;
  final VoidCallback onExport;
  final VoidCallback onCompare;
  final Color orange;
  final Color orangeDeep;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                onTap: onChat,
                child: Ink(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [orange, orangeDeep]),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Chat',
                        style: GoogleFonts.plusJakartaSans(
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
            child: OutlinedButton(
              onPressed: onExport,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.rule),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              child: Text(
                'Export',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: onCompare,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.rule),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              child: Text(
                'Compare',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
