import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analysis/risk_gauge.dart';
import '../../widgets/analysis/risk_style.dart';
import '../../widgets/analysis/soft_card.dart';
import 'clause_breakdown_page.dart';

/// Full risk visual dashboard.
class RiskDashboardPage extends StatelessWidget {
  const RiskDashboardPage({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[
      if (result.highRiskCount > 0)
        PieChartSectionData(
          value: result.highRiskCount.toDouble(),
          color: AppColors.riskHigh,
          title: '${result.highRiskCount}',
          radius: 36,
          titleStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.cloud,
            fontSize: 11,
          ),
        ),
      if (result.mediumRiskCount > 0)
        PieChartSectionData(
          value: result.mediumRiskCount.toDouble(),
          color: AppColors.riskMedium,
          title: '${result.mediumRiskCount}',
          radius: 36,
          titleStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.cloud,
            fontSize: 11,
          ),
        ),
      if (result.lowRiskCount > 0)
        PieChartSectionData(
          value: result.lowRiskCount.toDouble(),
          color: AppColors.riskLow,
          title: '${result.lowRiskCount}',
          radius: 36,
          titleStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.cloud,
            fontSize: 11,
          ),
        ),
      if (result.missingCount > 0)
        PieChartSectionData(
          value: result.missingCount.toDouble(),
          color: AppColors.riskMissing,
          title: '${result.missingCount}',
          radius: 36,
          titleStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.cloud,
            fontSize: 11,
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          'Risk dashboard',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, AppInsets.shellBottom(context)),
        children: [
          SoftCard(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              children: [
                RiskGauge(score: result.riskScore, size: 152),
                const SizedBox(height: 10),
                Text(
                  result.biasSummary,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Risk breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      pieTouchData: PieTouchData(enabled: false),
                      sections: sections,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _LegendRow(
                  color: AppColors.riskHigh,
                  label: 'High risk',
                  count: result.highRiskCount,
                  onTap: () => _openClauses(context, AnalysisRiskLevel.high),
                ),
                _LegendRow(
                  color: AppColors.riskMedium,
                  label: 'Medium risk',
                  count: result.mediumRiskCount,
                  onTap: () => _openClauses(context, AnalysisRiskLevel.medium),
                ),
                _LegendRow(
                  color: AppColors.riskLow,
                  label: 'Low risk',
                  count: result.lowRiskCount,
                  onTap: () => _openClauses(context, AnalysisRiskLevel.low),
                ),
                _LegendRow(
                  color: AppColors.riskMissing,
                  label: 'Missing',
                  count: result.missingCount,
                  onTap: () =>
                      _openClauses(context, AnalysisRiskLevel.missing),
                ),
              ],
            ),
          ),
          if (result.riskCategories.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Risk by category',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            ...result.riskCategories.map(
              (cat) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CategoryCard(
                  category: cat,
                  clauses: result.clauses
                      .where((c) => cat.clauseIds.contains(c.id))
                      .toList(),
                  onOpenClauses: () => _openClauses(context, cat.level),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openClauses(BuildContext context, AnalysisRiskLevel level) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClauseBreakdownPage(
          result: result,
          initialFilter: level,
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final Color color;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.mute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.category,
    required this.clauses,
    required this.onOpenClauses,
  });

  final RiskCategory category;
  final List<AnalysisClause> clauses;
  final VoidCallback onOpenClauses;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return SoftCard(
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cat.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              RiskChip(level: cat.level),
              Icon(
                _open ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: AppColors.mute,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            cat.summary,
            maxLines: _open ? null : 2,
            overflow: _open ? null : TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.35,
              color: AppColors.inkSoft,
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 8),
            ...widget.clauses.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '· Clause ${c.number} — ${c.title}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                onPressed: widget.onOpenClauses,
                child: Text(
                  'View in clause breakdown',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
