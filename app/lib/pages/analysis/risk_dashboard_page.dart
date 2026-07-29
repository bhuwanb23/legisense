import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analysis/risk_gauge.dart';
import '../../widgets/analysis/risk_style.dart';
import '../../widgets/analysis/soft_card.dart';
import 'clause_breakdown_page.dart';

/// Page 16 — Full risk visual dashboard.
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
          radius: 48,
          titleStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.cloud,
            fontSize: 12,
          ),
        ),
      if (result.mediumRiskCount > 0)
        PieChartSectionData(
          value: result.mediumRiskCount.toDouble(),
          color: AppColors.riskMedium,
          title: '${result.mediumRiskCount}',
          radius: 48,
          titleStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.cloud,
            fontSize: 12,
          ),
        ),
      if (result.lowRiskCount > 0)
        PieChartSectionData(
          value: result.lowRiskCount.toDouble(),
          color: AppColors.riskLow,
          title: '${result.lowRiskCount}',
          radius: 48,
          titleStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.cloud,
            fontSize: 12,
          ),
        ),
      if (result.missingCount > 0)
        PieChartSectionData(
          value: result.missingCount.toDouble(),
          color: AppColors.riskMissing,
          title: '${result.missingCount}',
          radius: 48,
          titleStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.cloud,
            fontSize: 12,
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        foregroundColor: AppColors.primaryNavy,
        title: Text(
          'Risk dashboard',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SoftCard(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              children: [
                RiskGauge(score: result.riskScore, size: 196),
                const SizedBox(height: 8),
                Text(
                  result.biasSummary,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Risk breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: sections,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _LegendRow(
                  color: AppColors.riskHigh,
                  label: 'High Risk Clauses',
                  count: result.highRiskCount,
                  onTap: () => _openClauses(context, AnalysisRiskLevel.high),
                ),
                _LegendRow(
                  color: AppColors.riskMedium,
                  label: 'Medium Risk Clauses',
                  count: result.mediumRiskCount,
                  onTap: () => _openClauses(context, AnalysisRiskLevel.medium),
                ),
                _LegendRow(
                  color: AppColors.riskLow,
                  label: 'Low Risk Clauses',
                  count: result.lowRiskCount,
                  onTap: () => _openClauses(context, AnalysisRiskLevel.low),
                ),
                _LegendRow(
                  color: AppColors.riskMissing,
                  label: 'Missing Clauses',
                  count: result.missingCount,
                  onTap: () =>
                      _openClauses(context, AnalysisRiskLevel.missing),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Risk by category',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              RiskChip(level: cat.level),
              const SizedBox(width: 4),
              Icon(
                _open ? Icons.expand_less : Icons.expand_more,
                color: AppColors.inkSoft,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cat.summary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: AppColors.inkSoft,
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 12),
            ...widget.clauses.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• Clause ${c.number} — ${c.title}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: widget.onOpenClauses,
                child: Text(
                  'View in clause breakdown',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
