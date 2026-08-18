import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/api/document_models.dart';
import '../../repositories/documents_repository.dart';
import '../../repositories/features_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';

/// Side-by-side document comparison (diff mode).
class CompareDocumentsPage extends StatefulWidget {
  const CompareDocumentsPage({super.key});

  @override
  State<CompareDocumentsPage> createState() => _CompareDocumentsPageState();
}

class _CompareDocumentsPageState extends State<CompareDocumentsPage> {
  final _docsRepo = DocumentsRepository();
  final _repo = FeaturesRepository();

  List<ApiDocument> _docs = [];
  ApiDocument? _docA;
  ApiDocument? _docB;
  bool _loadingDocs = true;
  bool _comparing = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    setState(() {
      _loadingDocs = true;
      _error = null;
    });
    try {
      final docs = await _docsRepo.list(limit: 100);
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _loadingDocs = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingDocs = false;
      });
    }
  }

  Future<void> _pick({required bool isA}) async {
    final picked = await showModalBottomSheet<ApiDocument>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final candidates = _docs.where((d) {
          if (isA) return d.id != _docB?.id;
          return d.id != _docA?.id;
        }).toList();
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  isA ? 'Version A (original)' : 'Version B (new)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              for (final d in candidates)
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(
                    d.originalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    d.isAnalyzed ? 'Analyzed' : 'Not analyzed yet',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11),
                  ),
                  onTap: () => Navigator.pop(context, d),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isA) {
        _docA = picked;
      } else {
        _docB = picked;
      }
      _result = null;
    });
  }

  Future<void> _compare() async {
    final a = _docA;
    final b = _docB;
    if (a == null || b == null) return;
    setState(() {
      _comparing = true;
      _error = null;
    });
    try {
      final result = await _repo.compareDocuments(
        documentIdA: a.id,
        documentIdB: b.id,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _comparing = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _comparing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _comparing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Compare documents',
              subtitle: 'Spot what changed between two versions',
              leading: AppHeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: _loadingDocs
                  ? const Center(child: CircularProgressIndicator())
                  : _docs.isEmpty
                      ? Center(
                          child: Text(
                            'Upload and analyze at least two documents to compare.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.mute,
                            ),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            8,
                            20,
                            AppInsets.shellBottom(context),
                          ),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _PickerCard(
                                    label: 'Version A',
                                    doc: _docA,
                                    onTap: () => _pick(isA: true),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Icon(
                                    Icons.compare_arrows_rounded,
                                    color: AppColors.mute,
                                  ),
                                ),
                                Expanded(
                                  child: _PickerCard(
                                    label: 'Version B',
                                    doc: _docB,
                                    onTap: () => _pick(isA: false),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed:
                                  _docA == null || _docB == null || _comparing
                                      ? null
                                      : _compare,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.ink,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: _comparing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Compare',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                            if (_result != null) ...[
                              const SizedBox(height: 20),
                              _DiffSummary(result: _result!),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({
    required this.label,
    required this.doc,
    required this.onTap,
  });

  final String label;
  final ApiDocument? doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mute,
                ),
              ),
              const Spacer(),
              if (doc == null)
                const Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.mute)
              else ...[
                Icon(
                  doc!.isAnalyzed
                      ? Icons.description_rounded
                      : Icons.hourglass_empty_rounded,
                  color: AppColors.ink,
                  size: 22,
                ),
                const SizedBox(height: 6),
                Text(
                  doc!.originalName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DiffSummary extends StatelessWidget {
  const _DiffSummary({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final added = (result['added'] as List?) ?? [];
    final removed = (result['removed'] as List?) ?? [];
    final changed = (result['changed'] as List?) ?? [];
    final same = (result['same'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Changes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              _CountRow(
                label: 'Added in B',
                count: added.length,
                color: const Color(0xFF22C55E),
              ),
              _CountRow(
                label: 'Removed',
                count: removed.length,
                color: AppColors.error,
              ),
              _CountRow(
                label: 'Changed',
                count: changed.length,
                color: const Color(0xFFE6A700),
              ),
              _CountRow(
                label: 'Unchanged',
                count: same.length,
                color: AppColors.mute,
              ),
            ],
          ),
        ),
        if (changed.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Section('Changed clauses', changed, accent: const Color(0xFFE6A700)),
        ],
        if (added.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Section('Added in Version B', added, accent: const Color(0xFF22C55E)),
        ],
        if (removed.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Section('Removed', removed, accent: AppColors.error),
        ],
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const Spacer(),
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.items, {required this.accent});

  final String title;
  final List<dynamic> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        ...items.take(12).map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          final num = m['number'];
          final t = m['title'] as String? ?? 'Clause';
          final textA = m['textA'] as String?;
          final textB = m['textB'] as String?;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border(left: BorderSide(color: accent, width: 3)),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clause $num — $t',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (textA != null && textA.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    textA,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.mute,
                    ),
                  ),
                ],
                if (textB != null && textB.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    textB,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
