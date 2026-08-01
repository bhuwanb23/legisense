import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/dashboard_mock.dart';
import '../../mappers/analysis_mapper.dart';
import '../../repositories/documents_repository.dart';
import '../../services/api_exception.dart';
import '../../services/session_prefs.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../utils/export_report.dart';
import '../../widgets/home/app_page_header.dart';
import '../analysis/analysis_loader_page.dart';

/// Documents library — live DocumentsRepository feed.
class DocumentsPage extends StatefulWidget {
  const DocumentsPage({
    super.key,
    this.onOpenUpload,
    this.initialQuery,
    this.initialFilter,
    this.onInitialApplied,
  });

  final VoidCallback? onOpenUpload;
  final String? initialQuery;
  final String? initialFilter;
  final VoidCallback? onInitialApplied;

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
    _applyInitial();
    _loadName();
    _loadDocs();
  }

  @override
  void didUpdateWidget(covariant DocumentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery ||
        widget.initialFilter != oldWidget.initialFilter) {
      _applyInitial();
    }
  }

  void _applyInitial() {
    var changed = false;
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _search.text = widget.initialQuery!;
      changed = true;
    }
    if (widget.initialFilter != null && widget.initialFilter!.isNotEmpty) {
      _filter = widget.initialFilter!;
      changed = true;
    }
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onInitialApplied?.call();
        if (mounted) setState(() {});
      });
    }
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
      useRootNavigator: true,
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
        await _share(doc);
      case 'delete':
        await _delete(doc);
    }
  }

  Future<void> _share(MockDocument doc) async {
    final id = int.tryParse(doc.id);
    if (id != null) {
      try {
        await exportAndShareReport(
          context,
          documentId: id,
          title: doc.title,
          format: 'pdf',
        );
        return;
      } catch (_) {
        // Fall through to text share.
      }
    }
    final risk = switch (doc.risk) {
      DocRisk.low => 'Low',
      DocRisk.medium => 'Medium',
      DocRisk.high => 'High',
    };
    final text = StringBuffer()
      ..writeln(doc.title)
      ..writeln('Type: ${doc.typeLabel}')
      ..writeln('Risk: $risk (${doc.riskScore}/100)')
      ..writeln()
      ..writeln('Shared from Legisense — Your AI Legal Advisor');
    await SharePlus.instance.share(ShareParams(text: text.toString()));
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                height: 48,
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
                      size: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  final selected = _filter == c.id;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = c.id),
                    child: SizedBox(
                      width: 60,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: selected
                                  ? Border.all(color: AppColors.ink, width: 1.6)
                                  : null,
                              boxShadow: AppShadows.soft,
                            ),
                            child: Icon(c.icon, color: c.fg, size: 24),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text(
                'All Documents',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
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
                                      padding: EdgeInsets.fromLTRB(
                                        20,
                                        16,
                                        12,
                                        AppInsets.shellBottom(context),
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
                                                  width: 40,
                                                  height: 40,
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
