import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repositories/analysis_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';

/// Jurisdiction compliance flags for a document.
class JurisdictionFlagsPage extends StatefulWidget {
  const JurisdictionFlagsPage({super.key, required this.documentId});

  final int documentId;

  @override
  State<JurisdictionFlagsPage> createState() => _JurisdictionFlagsPageState();
}

class _JurisdictionFlagsPageState extends State<JurisdictionFlagsPage> {
  bool _loading = true;
  String? _error;
  final List<({String title, String body, String severity})> _items = [];

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
          await AnalysisRepository().jurisdictionFlags(widget.documentId);
      final flags = data['flags'];
      final items = <({String title, String body, String severity})>[];
      if (flags is Map) {
        for (final severity in ['critical', 'warning', 'info']) {
          final list = flags[severity];
          if (list is! List) continue;
          for (final raw in list.whereType<Map>()) {
            final m = Map<String, dynamic>.from(raw);
            items.add((
              title: (m['title'] ?? m['flagType'] ?? m['type'] ?? severity)
                  .toString(),
              body: (m['message'] ??
                      m['description'] ??
                      m['explanation'] ??
                      m['detail'] ??
                      '')
                  .toString(),
              severity: severity,
            ));
          }
        }
      } else if (flags is List) {
        for (final raw in flags.whereType<Map>()) {
          final m = Map<String, dynamic>.from(raw);
          items.add((
            title: (m['title'] ?? m['flagType'] ?? 'Flag').toString(),
            body: (m['message'] ?? m['description'] ?? '').toString(),
            severity: (m['severity'] ?? 'info').toString(),
          ));
        }
      }
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
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

  Color _fg(String s) {
    switch (s.toLowerCase()) {
      case 'critical':
        return AppColors.riskHigh;
      case 'warning':
        return AppColors.riskMedium;
      default:
        return AppColors.ink;
    }
  }

  Color _bg(String s) {
    switch (s.toLowerCase()) {
      case 'critical':
        return AppColors.riskHighBg;
      case 'warning':
        return AppColors.riskMediumBg;
      default:
        return AppColors.chip;
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
              title: 'Jurisdiction flags',
              subtitle: 'Compliance checks',
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
                                'No jurisdiction flags.',
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
                                              color: _bg(item.severity),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadii.pill),
                                            ),
                                            child: Text(
                                              item.severity,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: _fg(item.severity),
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
