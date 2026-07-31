import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/dashboard_mock.dart';
import '../../mappers/analysis_mapper.dart';
import '../../repositories/deadlines_repository.dart';
import '../../repositories/documents_repository.dart';
import '../../services/api_exception.dart';
import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';
import '../../widgets/home/doc_type_filters.dart';
import '../../widgets/home/featured_doc_card.dart';
import '../../widgets/home/home_search_bar.dart';
import '../../widgets/home/recent_doc_tile.dart';
import '../../widgets/home/section_header.dart';
import '../../widgets/home/stat_card.dart';
import '../analysis/analysis_loader_page.dart';
import '../deadlines/deadlines_page.dart';

/// Home — TripGlide Operate workbench (live documents).
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
  List<MockDocument> _docs = [];
  int _deadlineCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadDocs();
  }

  Future<void> _loadName() async {
    final display = await SessionPrefs.displayName();
    final email = await SessionPrefs.userEmail();
    if (!mounted) return;
    setState(() => _name = _resolveName(display, email));
  }

  String _resolveName(String? display, String? email) {
    if (display != null && display.trim().isNotEmpty) return display.trim();
    if (email != null && email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) {
        return local[0].toUpperCase() + local.substring(1);
      }
    }
    return 'there';
  }

  Future<void> _loadDocs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiDocs = await DocumentsRepository().list();
      final mapped = apiDocs.map(AnalysisMapper.toMockDocument).toList();
      var deadlines = 0;
      try {
        final upcoming = await DeadlinesRepository().upcoming();
        deadlines = upcoming.length;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _docs = mapped;
        _deadlineCount = deadlines;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<MockDocument> get _filtered {
    if (_filterId == 'all') return _docs;
    return _docs
        .where((d) => d.typeId.contains(_filterId) || d.typeLabel.toLowerCase().contains(_filterId))
        .toList();
  }

  void _openDoc(MockDocument doc) {
    final id = int.tryParse(doc.id);
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalysisLoaderPage(
          documentId: id,
          titleHint: doc.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filtered;
    final analyzed = _docs.where((d) => d.riskScore > 0).length;
    final highRisk = _docs.where((d) => d.risk == DocRisk.high).length;
    final featured = docs.isNotEmpty ? docs.first : null;

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadDocs,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
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
                        icon: Icons.refresh_rounded,
                        onTap: _loadDocs,
                      ),
                      const SizedBox(width: 8),
                      AppHeaderIconButton(
                        icon: Icons.notifications_none_rounded,
                        onTap: widget.onOpenNotifications,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                HomeSearchBar(
                  onSearch: widget.onOpenDocuments,
                  onFilter: widget.onOpenDocuments,
                ),
                const SizedBox(height: 20),
                Text(
                  'Select your next review',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                DocTypeFilters(
                  selectedId: _filterId,
                  onSelected: (id) => setState(() => _filterId = id),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.error,
                          ),
                        ),
                        TextButton(onPressed: _loadDocs, child: const Text('Retry')),
                      ],
                    ),
                  )
                else if (featured != null)
                  FeaturedDocCard(
                    document: featured,
                    onTap: () => _openDoc(featured),
                  )
                else
                  _EmptyUploadHint(onUpload: widget.onOpenUpload),
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'Quick stats',
                  actionLabel: 'Deadlines',
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DeadlinesPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    StatCard(
                      label: 'Total analyzed',
                      value: '$analyzed',
                      icon: Icons.analytics_outlined,
                    ),
                    StatCard(
                      label: 'High risk',
                      value: '$highRisk',
                      icon: Icons.warning_amber_rounded,
                      accent: true,
                    ),
                    StatCard(
                      label: 'Deadlines',
                      value: '$_deadlineCount',
                      icon: Icons.event_outlined,
                    ),
                    StatCard(
                      label: 'Documents',
                      value: '${_docs.length}',
                      icon: Icons.folder_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'Recent documents',
                  showAddButton: true,
                  onAction: widget.onOpenUpload,
                ),
                const SizedBox(height: 12),
                if (!_loading && docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No documents yet. Upload your first contract.',
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
                        onTap: () => _openDoc(doc),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyUploadHint extends StatelessWidget {
  const _EmptyUploadHint({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onUpload,
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cloud_upload_rounded, size: 36),
              const Spacer(),
              Text(
                'Upload your first document',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PDF, DOCX, scan, paste, or URL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
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
