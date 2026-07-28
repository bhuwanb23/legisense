import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/dashboard_mock.dart';
import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/home/doc_type_filters.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/recent_doc_tile.dart';
import '../../widgets/home/stat_card.dart';
import '../../widgets/home/welcome_banner.dart';
import '../analysis/analysis_stub_page.dart';

/// Home dashboard body — hosted inside [MainShell].
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

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.skyMist, AppColors.skyWash],
        ),
      ),
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
                  ),
                  const SizedBox(height: 22),
                  WelcomeBanner(name: _name),
                  const SizedBox(height: 18),
                  AuthPrimaryButton(
                    label: 'Upload / Scan Document',
                    onPressed: widget.onOpenUpload,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Document types',
                    style: GoogleFonts.epilogue(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DocTypeFilters(
                    selectedId: _filterId,
                    onSelected: (id) => setState(() => _filterId = id),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick stats',
                    style: GoogleFonts.epilogue(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total analyzed',
                          value: '${stats.totalAnalyzed}',
                          icon: Icons.analytics_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'High risk',
                          value: '${stats.highRisk}',
                          icon: Icons.warning_amber_rounded,
                          accent: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Deadlines',
                          value: '${stats.pendingDeadlines}',
                          icon: Icons.event_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent documents',
                          style: GoogleFonts.epilogue(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onOpenDocuments,
                        child: Text(
                          'See all',
                          style: GoogleFonts.epilogue(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentSky,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
}
