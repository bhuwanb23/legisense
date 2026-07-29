import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/dashboard_mock.dart';
import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';
import '../../widgets/home/doc_type_filters.dart';
import '../../widgets/home/featured_doc_card.dart';
import '../../widgets/home/home_search_bar.dart';
import '../../widgets/home/recent_doc_tile.dart';
import '../../widgets/home/section_header.dart';
import '../../widgets/home/stat_card.dart';
import '../analysis/analysis_stub_page.dart';

/// Home — TripGlide Operate workbench.
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

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = DashboardMock.filtered(_filterId);
    final stats = DashboardMock.stats;
    final featured = docs.isNotEmpty
        ? docs.first
        : (DashboardMock.recentDocuments.isNotEmpty
            ? DashboardMock.recentDocuments.first
            : null);

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader.greeting(
                name: _name,
                padding: EdgeInsets.zero,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppHeaderIconButton(
                      icon: Icons.search_rounded,
                      onTap: () => _toast('Search comes with the backend.'),
                    ),
                    const SizedBox(width: 8),
                    AppHeaderIconButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: widget.onOpenNotifications,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              HomeSearchBar(
                onSearch: () => _toast('Search comes with the backend.'),
                onFilter: () => _toast('Filters open on Documents.'),
              ),
              const SizedBox(height: 28),
              Text(
                'Select your next review',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              DocTypeFilters(
                selectedId: _filterId,
                onSelected: (id) => setState(() => _filterId = id),
              ),
              const SizedBox(height: 20),
              if (featured != null)
                FeaturedDocCard(
                  document: featured,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AnalysisStubPage(document: featured),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'Quick stats',
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
                childAspectRatio: 1.15,
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.mute,
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
            ],
          ),
        ),
      ),
    );
  }
}
