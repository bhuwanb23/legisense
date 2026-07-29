import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/dashboard_mock.dart';
import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/doc_type_filters.dart';
import '../../widgets/home/featured_doc_card.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/recent_doc_tile.dart';
import '../../widgets/home/section_header.dart';
import '../../widgets/home/stat_card.dart';
import '../analysis/analysis_stub_page.dart';

/// Home dashboard body — hosted inside [MainShell].
/// Layout inspired by Dribbble smart-home dashboard.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onOpenUpload,
    required this.onOpenDocuments,
    required this.onOpenNotifications,
  });

  final VoidCallback onOpenUpload;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenNotifications;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _name = 'there';
  String _filterId = 'all';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final display = await SessionPrefs.displayName();
    final email = await SessionPrefs.userEmail();
    if (!mounted) return;
    setState(() => _name = _resolveName(display, email));
  }

  String _resolveName(String? display, String? email) {
    if (display != null && display.trim().isNotEmpty) {
      return display.trim();
    }
    if (email != null && email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) {
        return local[0].toUpperCase() + local.substring(1);
      }
    }
    return 'there';
  }

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final docs = DashboardMock.filtered(_filterId);
    final stats = DashboardMock.stats;
    final recentDoc =
        DashboardMock.recentDocuments.isNotEmpty
            ? DashboardMock.recentDocuments.first
            : null;

    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  HomeHeader(
                    greeting: _timeGreeting,
                    name: _name,
                    onNotifications: widget.onOpenNotifications,
                    onSearch: _onSearch,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your Legal\nDashboard',
                    style: GoogleFonts.spectral(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      letterSpacing: -0.5,
                      color: AppColors.ink,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DocTypeFilters(
                    selectedId: _filterId,
                    onSelected: (id) => setState(() => _filterId = id),
                  ),
                  const SizedBox(height: 24),
                  if (recentDoc != null)
                    FeaturedDocCard(
                      document: recentDoc,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                AnalysisStubPage(document: recentDoc),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 28),
                  SectionHeader(
                    title: 'Quick stats',
                    showAddButton: false,
                    actionLabel: 'See all',
                    onAction: widget.onOpenDocuments,
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      StatCard(
                        label: 'Total analyzed',
                        value: '${stats.totalAnalyzed}',
                        icon: Icons.analytics_outlined,
                      ),
                      StatCard(
                        label: 'High risk',
                        value: '${stats.highRisk}',
                        icon: Icons.warning_amber_rounded,
                        accent: true,
                      ),
                      StatCard(
                        label: 'Deadlines',
                        value: '${stats.pendingDeadlines}',
                        icon: Icons.event_outlined,
                      ),
                      StatCard(
                        label: 'Documents',
                        value: '${DashboardMock.recentDocuments.length}',
                        icon: Icons.folder_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SectionHeader(
                    title: 'Recent documents',
                    showAddButton: true,
                    onAction: widget.onOpenUpload,
                  ),
                  const SizedBox(height: 14),
                  if (docs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No documents in this filter yet.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.epilogue(
                          fontSize: 14,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    )
                  else
                    ...docs.take(5).map(
                      (doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RecentDocTile(
                          document: doc,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    AnalysisStubPage(document: doc),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Search comes with the backend.',
          style: GoogleFonts.epilogue(fontSize: 14),
        ),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
