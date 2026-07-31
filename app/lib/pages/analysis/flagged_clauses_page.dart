import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repositories/analysis_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';

/// Pattern-flagged clauses for a document.
class FlaggedClausesPage extends StatefulWidget {
  const FlaggedClausesPage({super.key, required this.documentId});

  final int documentId;

  @override
  State<FlaggedClausesPage> createState() => _FlaggedClausesPageState();
}

class _FlaggedClausesPageState extends State<FlaggedClausesPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AnalysisRepository().flaggedClauses(widget.documentId);
      final raw = data['flaggedClauses'] ?? data['clauses'] ?? data['items'];
      final list = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _items = list;
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppPageHeader(
              title: 'Flagged clauses',
              subtitle: 'Risk pattern matches',
              leading: AppHeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!,
                                  style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.mute)),
                              TextButton(
                                  onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _items.isEmpty
                          ? Center(
                              child: Text(
                                'No flagged clauses.',
                                style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.mute),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final m = _items[i];
                                final clauseNum = m['clauseNumber'];
                                final title =
                                    (m['clauseTitle'] ?? m['title'] ?? 'Clause')
                                        .toString();
                                final risk =
                                    (m['riskLevel'] ?? '').toString();
                                final plain = (m['plainEnglishText'] ??
                                        m['originalText'] ??
                                        '')
                                    .toString();
                                final patterns = m['patterns'];
                                var patternHint = '';
                                if (patterns is List && patterns.isNotEmpty) {
                                  final first = patterns.first;
                                  if (first is Map) {
                                    final p = first['pattern'];
                                    if (p is Map) {
                                      patternHint =
                                          (p['name'] ?? p['explanation'] ?? '')
                                              .toString();
                                    }
                                  }
                                }
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.md),
                                    boxShadow: AppShadows.soft,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              clauseNum != null
                                                  ? 'Clause $clauseNum — $title'
                                                  : title,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                          if (risk.isNotEmpty)
                                            Text(
                                              risk,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.riskHigh,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (patternHint.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          patternHint,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ],
                                      if (plain.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          plain,
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: AppColors.mute,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
