import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repositories/analysis_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';

/// Missing / incomplete clauses for a document.
class MissingClausesPage extends StatefulWidget {
  const MissingClausesPage({super.key, required this.documentId});

  final int documentId;

  @override
  State<MissingClausesPage> createState() => _MissingClausesPageState();
}

class _MissingClausesPageState extends State<MissingClausesPage> {
  bool _loading = true;
  String? _error;
  final List<({String title, String body, String tag})> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _pushItems(List? list, String tag) {
    if (list == null) return;
    for (final raw in list) {
      if (raw is String) {
        _items.add((title: raw, body: '', tag: tag));
        continue;
      }
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        _items.add((
          title: (m['name'] ?? m['title'] ?? m['clause'] ?? 'Missing clause')
              .toString(),
          body: (m['why_needed'] ??
                  m['reason'] ??
                  m['description'] ??
                  m['explanation'] ??
                  '')
              .toString(),
          tag: tag,
        ));
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AnalysisRepository().missingClauses(widget.documentId);
      _items.clear();
      final missing = data['missing'];
      if (missing is Map) {
        _pushItems(missing['critical'] as List?, 'critical');
        _pushItems(missing['recommended'] as List?, 'recommended');
        _pushItems(missing['optional'] as List?, 'optional');
      } else if (missing is List) {
        _pushItems(missing, 'missing');
      }
      _pushItems(data['incomplete'] as List?, 'incomplete');
      if (!mounted) return;
      setState(() => _loading = false);
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
              title: 'Missing clauses',
              subtitle: 'Gaps & incompleteness',
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
                                'No missing clauses.',
                                style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.mute),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 110),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final item = _items[i];
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
                                              item.title,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.riskMissingBg,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadii.pill),
                                            ),
                                            child: Text(
                                              item.tag,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.riskMissing,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item.body.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          item.body,
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
