import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/dashboard_mock.dart';
import '../../mappers/analysis_mapper.dart';
import '../../repositories/documents_repository.dart';
import '../../services/api_exception.dart';
import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';
import '../analysis/analysis_loader_page.dart';

/// Documents library — live DocumentsRepository feed.
class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key, this.onOpenUpload});

  final VoidCallback? onOpenUpload;

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final _search = TextEditingController();
  final _repo = DocumentsRepository();
  String _filter = 'all';
  String _name = 'Reader';
  List<MockDocument> _docs = [];
  bool _loading = true;
  String? _error;

  static const _categories =
      <({String id, String label, Color tint, Color fg, IconData icon})>[
    (
      id: 'all',
      label: 'All',
      tint: Color(0xFFFFF3CD),
      fg: Color(0xFFE6A700),
      icon: Icons.folder_rounded,
    ),
    (
      id: 'nda',
      label: 'NDA',
      tint: Color(0xFFFFE5E5),
      fg: Color(0xFFE53935),
      icon: Icons.picture_as_pdf_rounded,
    ),
    (
      id: 'lease',
      label: 'Lease',
      tint: Color(0xFFE3F2FD),
      fg: Color(0xFF1E88E5),
      icon: Icons.description_rounded,
    ),
    (
      id: 'employment',
      label: 'Job',
      tint: Color(0xFFE8F5E9),
      fg: Color(0xFF43A047),
      icon: Icons.work_rounded,
    ),
    (
      id: 'loan',
      label: 'Loan',
      tint: Color(0xFFFFF3E0),
      fg: Color(0xFFFB8C00),
      icon: Icons.account_balance_rounded,
    ),
  ];

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
    setState(() {
      if (display != null && display.trim().isNotEmpty) {
        _name = display.trim().split(' ').first;
      } else if (email != null && email.contains('@')) {
        final local = email.split('@').first;
        if (local.isNotEmpty) {
          _name = local[0].toUpperCase() + local.substring(1);
        }
      }
    });
  }

  Future<void> _loadDocs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiDocs = await _repo.list();
      if (!mounted) return;
      setState(() {
        _docs = apiDocs.map(AnalysisMapper.toMockDocument).toList();
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<MockDocument> get _visible {
    var list = _filter == 'all'
        ? List<MockDocument>.from(_docs)
        : _docs
            .where(
              (d) =>
                  d.typeId.contains(_filter) ||
                  d.typeLabel.toLowerCase().contains(_filter),
            )
            .toList();
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (d) =>
                d.title.toLowerCase().contains(q) ||
                d.typeLabel.toLowerCase().contains(q),
          )
          .toList();
    }
    list.sort((a, b) => a.daysAgo.compareTo(b.daysAgo));
    return list;
  }

  String _sizeLabel(MockDocument doc) {
    final bytes = doc.fileSize;
    if (bytes == null || bytes <= 0) return doc.relativeDate;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _dateLabel(MockDocument doc) {
    final d = DateTime.now().subtract(Duration(days: doc.daysAgo));
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  String _metaLine(MockDocument doc) {
    if (doc.isFailed) return '${_dateLabel(doc)}  ·  Failed';
    if (doc.isProcessing) return '${_dateLabel(doc)}  ·  Processing…';
    return '${_dateLabel(doc)}  ·  ${_sizeLabel(doc)}';
  }

  ({Color tint, Color fg, IconData icon}) _styleFor(MockDocument doc) {
    final match = _categories.where((c) => c.id == doc.typeId || doc.typeId.contains(c.id));
    if (match.isNotEmpty) {
      final c = match.first;
      return (tint: c.tint, fg: c.fg, icon: c.icon);
    }
    return (
      tint: const Color(0xFFEEEEEE),
      fg: AppColors.ink,
      icon: Icons.insert_drive_file_rounded,
    );
  }

  void _openAnalysis(MockDocument doc) {
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

  Future<void> _delete(MockDocument doc) async {
    final id = int.tryParse(doc.id);
    if (id == null) return;
    try {
      await _repo.delete(id);
      if (!mounted) return;
      setState(() => _docs.removeWhere((d) => d.id == doc.id));
      _toast('Removed from library.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString());
    }
  }

  Future<void> _menuFor(MockDocument doc) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('View analysis'),
                onTap: () => Navigator.pop(context, 'view'),
              ),
              ListTile(
                leading: const Icon(Icons.ios_share_rounded),
                title: const Text('Share'),
                onTap: () => Navigator.pop(context, 'share'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'view':
        _openAnalysis(doc);
      case 'share':
        _toast('Share for “${doc.title}” comes soon.');
      case 'delete':
        await _delete(doc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = _visible;

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Documents',
              subtitle: '$_greeting, $_name',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppHeaderIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: _loadDocs,
                  ),
                  const SizedBox(width: 10),
                  AppHeaderIconButton(
                    icon: Icons.note_add_outlined,
                    onTap: () => widget.onOpenUpload?.call(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: AppShadows.soft,
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search your documents...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.mute,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.mute,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  final selected = _filter == c.id;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = c.id),
                    child: SizedBox(
                      width: 64,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: selected
                                  ? Border.all(color: AppColors.ink, width: 1.6)
                                  : null,
                              boxShadow: AppShadows.soft,
                            ),
                            child: Icon(c.icon, color: c.fg, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected ? AppColors.ink : AppColors.mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Material(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    setState(() => _filter = 'all');
                    _loadDocs();
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recently Added',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'View your latest files in one place',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  Text(
                    'All Documents',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _filter = 'all'),
                    child: Text(
                      'See all',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mute,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: AppShadows.soft,
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.mute,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: _loadDocs,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _docs.isEmpty
                            ? Center(
                                child: Text(
                                  'No documents yet.\nUpload one to get started.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.mute,
                                  ),
                                ),
                              )
                            : docs.isEmpty
                                ? Center(
                                    child: Text(
                                      'No documents match.',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.mute,
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadDocs,
                                    child: ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        16,
                                        12,
                                        110,
                                      ),
                                      itemCount: docs.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 6),
                                      itemBuilder: (context, index) {
                                        final doc = docs[index];
                                        final style = _styleFor(doc);
                                        return InkWell(
                                          onTap: () => _openAnalysis(doc),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: style.tint,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      14,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    style.icon,
                                                    color: style.fg,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        doc.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors.ink,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _metaLine(doc),
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontSize: 12,
                                                          color: doc.isFailed
                                                              ? AppColors.error
                                                              : AppColors.mute,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (doc.isFailed ||
                                                    doc.isProcessing)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      right: 4,
                                                    ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: doc.isFailed
                                                            ? AppColors
                                                                .riskHighBg
                                                            : AppColors.chip,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          AppRadii.pill,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        doc.isFailed
                                                            ? 'Failed'
                                                            : 'Busy',
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: doc.isFailed
                                                              ? AppColors
                                                                  .riskHigh
                                                              : AppColors
                                                                  .inkSoft,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                IconButton(
                                                  onPressed: () =>
                                                      _menuFor(doc),
                                                  icon: const Icon(
                                                    Icons.more_vert_rounded,
                                                    color: AppColors.mute,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
