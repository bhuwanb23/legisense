import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repositories/analysis_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';

/// Counter-clause suggestions for risky language.
class CounterClausesPage extends StatefulWidget {
  const CounterClausesPage({super.key, required this.documentId});

  final int documentId;

  @override
  State<CounterClausesPage> createState() => _CounterClausesPageState();
}

class _CounterClausesPageState extends State<CounterClausesPage> {
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
      final data =
          await AnalysisRepository().counterClauses(widget.documentId);
      final raw = data['clauses'] ?? data['counterClauses'];
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

  Future<void> _copy(String text, int? clauseId) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (clauseId != null) {
      try {
        await AnalysisRepository().markCounterUsed(
          documentId: widget.documentId,
          clauseId: clauseId,
        );
      } catch (_) {}
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied suggestion',
            style: GoogleFonts.plusJakartaSans()),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              title: 'Counter clauses',
              subtitle: 'Negotiation suggestions',
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
                                'No counter suggestions yet.',
                                style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.mute),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    AppInsets.shellBottom(context),
                                  ),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final m = _items[i];
                                final id = (m['id'] as num?)?.toInt();
                                final clauseNum = m['clauseNumber'];
                                final title =
                                    (m['clauseTitle'] ?? 'Clause').toString();
                                final suggestion =
                                    (m['counterSuggestion'] ?? '').toString();
                                final reason =
                                    (m['riskReason'] ?? '').toString();
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
                                      Text(
                                        clauseNum != null
                                            ? 'Clause $clauseNum — $title'
                                            : title,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      if (reason.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          reason,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: AppColors.mute,
                                          ),
                                        ),
                                      ],
                                      if (suggestion.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          suggestion,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            height: 1.45,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () =>
                                                _copy(suggestion, id),
                                            icon: const Icon(
                                              Icons.copy_rounded,
                                              size: 16,
                                            ),
                                            label: Text(
                                              'Copy',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
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
