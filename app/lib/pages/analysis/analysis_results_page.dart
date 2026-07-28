import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analysis/risk_gauge.dart';
import '../../widgets/analysis/risk_style.dart';
import '../../widgets/analysis/soft_card.dart';
import 'clause_breakdown_page.dart';
import 'document_summary_page.dart';
import 'plain_language_page.dart';
import 'risk_dashboard_page.dart';

/// Page 13 — Master analysis results.
class AnalysisResultsPage extends StatefulWidget {
  const AnalysisResultsPage({super.key, required this.result});

  final AnalysisResult result;

  @override
  State<AnalysisResultsPage> createState() => _AnalysisResultsPageState();
}

class _AnalysisResultsPageState extends State<AnalysisResultsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  AnalysisResult get r => widget.result;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: AppColors.skyMist,
      appBar: AppBar(
        backgroundColor: AppColors.skyMist,
        elevation: 0,
        foregroundColor: AppColors.primaryNavy,
        title: Text(
          'Analysis',
          style: GoogleFonts.epilogue(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SoftCard(
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
                                      'Document: "${r.documentTitle}"',
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
                              Text(
                                'Type: ${r.typeEmoji} ${r.documentType}',
                                style: GoogleFonts.epilogue(
                                  fontSize: 14,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pages: ${r.pageCount}   |   Parties: ${r.partyCount}',
                                style: GoogleFonts.epilogue(
                                  fontSize: 13,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Analyzed: ${r.analyzedLabel}',
                                style: GoogleFonts.epilogue(
                                  fontSize: 13,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SoftCard(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                          child: Column(
                            children: [
                              RiskGauge(score: r.riskScore),
                              const SizedBox(height: 12),
                              Text(
                                r.biasSummary,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.epilogue(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          RiskDashboardPage(result: r),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Open risk dashboard',
                                  style: GoogleFonts.epilogue(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentSky,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: MiniStatCard(
                                title: 'Parties',
                                value: '${r.partyCount} found',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          DocumentSummaryPage(result: r),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MiniStatCard(
                                title: 'Duration',
                                value: r.durationLabel,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          DocumentSummaryPage(result: r),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MiniStatCard(
                                title: 'Key Dates',
                                value: '${r.keyDatesCount} found',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          DocumentSummaryPage(result: r),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabs,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: AppColors.primaryNavy,
                      unselectedLabelColor: AppColors.inkSoft,
                      indicatorColor: AppColors.primaryNavy,
                      labelStyle: GoogleFonts.epilogue(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: GoogleFonts.epilogue(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Summary'),
                        Tab(text: 'Clauses'),
                        Tab(text: 'Plain English'),
                        Tab(text: 'Risks'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabs,
                children: [
                  _SummaryTab(
                    result: r,
                    onOpenFull: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DocumentSummaryPage(result: r),
                        ),
                      );
                    },
                  ),
                  _ClausesPreviewTab(
                    result: r,
                    onOpenFull: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ClauseBreakdownPage(result: r),
                        ),
                      );
                    },
                  ),
                  _PlainEnglishTab(
                    result: r,
                    onOpenFull: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PlainLanguagePage(result: r),
                        ),
                      );
                    },
                  ),
                  _RisksTab(
                    result: r,
                    onOpenDashboard: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RiskDashboardPage(result: r),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.cloud,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNavy.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionChipButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chat',
                    onTap: () => _toast('Chat with Document comes next.'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionChipButton(
                    icon: Icons.ios_share_rounded,
                    label: 'Export',
                    onTap: () => _toast('Export report comes with backend.'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionChipButton(
                    icon: Icons.compare_arrows_rounded,
                    label: 'Compare',
                    onTap: () => _toast('Version compare comes later.'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.skyWash,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppColors.primaryNavy),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.epilogue(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height + 8;

  @override
  double get maxExtent => tabBar.preferredSize.height + 8;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.skyMist,
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.result, required this.onOpenFull});

  final AnalysisResult result;
  final VoidCallback onOpenFull;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        SoftCard(
          child: Text(
            result.overview,
            style: GoogleFonts.epilogue(
              fontSize: 14,
              height: 1.5,
              color: AppColors.inkSoft,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onOpenFull,
          child: Text(
            'Open full summary',
            style: GoogleFonts.epilogue(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClausesPreviewTab extends StatelessWidget {
  const _ClausesPreviewTab({required this.result, required this.onOpenFull});

  final AnalysisResult result;
  final VoidCallback onOpenFull;

  @override
  Widget build(BuildContext context) {
    final preview = result.clauses.take(4).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        ...preview.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              onTap: onOpenFull,
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
                  const SizedBox(height: 8),
                  Text(
                    c.originalText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.epilogue(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: onOpenFull,
          child: Text(
            'See all clauses',
            style: GoogleFonts.epilogue(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlainEnglishTab extends StatelessWidget {
  const _PlainEnglishTab({
    required this.result,
    required this.onOpenFull,
  });

  final AnalysisResult result;
  final VoidCallback onOpenFull;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        ...result.clauses
            .where((c) => c.risk != AnalysisRiskLevel.missing)
            .take(6)
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  onTap: onOpenFull,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: GoogleFonts.epilogue(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.plainEnglish,
                        style: GoogleFonts.epilogue(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        TextButton(
          onPressed: onOpenFull,
          child: Text(
            'Open plain language translator',
            style: GoogleFonts.epilogue(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
        ),
      ],
    );
  }
}

class _RisksTab extends StatelessWidget {
  const _RisksTab({required this.result, required this.onOpenDashboard});

  final AnalysisResult result;
  final VoidCallback onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        SoftCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Count('High', result.highRiskCount, AnalysisRiskLevel.high),
              _Count('Med', result.mediumRiskCount, AnalysisRiskLevel.medium),
              _Count('Low', result.lowRiskCount, AnalysisRiskLevel.low),
              _Count('Miss', result.missingCount, AnalysisRiskLevel.missing),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...result.riskCategories.map(
          (cat) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              onTap: onOpenDashboard,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cat.title,
                      style: GoogleFonts.epilogue(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                  RiskChip(level: cat.level),
                ],
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: onOpenDashboard,
          child: Text(
            'Open risk dashboard',
            style: GoogleFonts.epilogue(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.n, this.level);

  final String label;
  final int n;
  final AnalysisRiskLevel level;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$n',
          style: GoogleFonts.epilogue(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: RiskStyle.color(level),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.epilogue(
            fontSize: 11,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}
