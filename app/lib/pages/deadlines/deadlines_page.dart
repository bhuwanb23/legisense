import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../repositories/deadlines_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';

class DeadlinesPage extends StatefulWidget {
  const DeadlinesPage({super.key, this.documentId});

  final int? documentId;

  @override
  State<DeadlinesPage> createState() => _DeadlinesPageState();
}

class _DeadlinesPageState extends State<DeadlinesPage> {
  final _repo = DeadlinesRepository();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

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
      final list = widget.documentId != null
          ? await _repo.forDocument(widget.documentId!)
          : await _repo.upcoming();
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
    }
  }

  Future<void> _complete(int id) async {
    await _repo.complete(id);
    await _load();
  }

  Future<void> _dismiss(int id) async {
    await _repo.dismiss(id);
    await _load();
  }

  Future<void> _exportIcs() async {
    final ids = _items
        .map((d) => (d['id'] as num?)?.toInt())
        .whereType<int>()
        .toList();
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No deadlines to export')),
      );
      return;
    }
    try {
      final ics = await _repo.exportIcsText(ids);
      if (ics == null || ics.isEmpty) {
        throw Exception('Empty calendar');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/legisense-deadlines.ics');
      await file.writeAsString(ics);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/calendar')],
          subject: 'Legisense deadlines',
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
              title: 'Deadlines',
              subtitle: 'Obligations & reminders',
              leading: AppHeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              trailing: _items.isEmpty
                  ? null
                  : AppHeaderIconButton(
                      icon: Icons.ios_share_rounded,
                      onTap: _exportIcs,
                    ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _items.isEmpty
                          ? Center(
                              child: Text(
                                'No upcoming deadlines',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.mute,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                padding:
                                    EdgeInsets.fromLTRB(
                                      24,
                                      8,
                                      24,
                                      AppInsets.shellBottom(context),
                                    ),
                                itemCount: _items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final d = _items[i];
                                  final id = (d['id'] as num?)?.toInt();
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
                                          d['title']?.toString() ?? 'Deadline',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Due ${d['dueDate'] ?? '—'} · ${d['urgencyLevel'] ?? ''}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: AppColors.mute,
                                          ),
                                        ),
                                        if (d['description'] != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            d['description'].toString(),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                        if (id != null) ...[
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              TextButton(
                                                onPressed: () => _complete(id),
                                                child: const Text('Complete'),
                                              ),
                                              TextButton(
                                                onPressed: () => _dismiss(id),
                                                child: const Text('Dismiss'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
