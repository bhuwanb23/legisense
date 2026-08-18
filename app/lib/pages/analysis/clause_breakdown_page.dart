import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../repositories/analysis_repository.dart';
import '../../repositories/features_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analysis/risk_style.dart';
import '../../widgets/analysis/soft_card.dart';
import '../chat/chat_page.dart';
import 'risk_dashboard_page.dart';
import 'plain_language_page.dart';

enum _ClauseFilter { all, high, medium, low, missing }

/// Page 15 — Clause-by-clause breakdown.
class ClauseBreakdownPage extends StatefulWidget {
  const ClauseBreakdownPage({
    super.key,
    required this.result,
    this.initialFilter,
    this.initialCategoryFilter,
  });

  final AnalysisResult result;
  final AnalysisRiskLevel? initialFilter;
  /// When set, only clauses in this risk_category are shown.
  final String? initialCategoryFilter;

  @override
  State<ClauseBreakdownPage> createState() => _ClauseBreakdownPageState();
}

class _ClauseBreakdownPageState extends State<ClauseBreakdownPage> {
  late _ClauseFilter _filter = switch (widget.initialFilter) {
    AnalysisRiskLevel.high => _ClauseFilter.high,
    AnalysisRiskLevel.medium => _ClauseFilter.medium,
    AnalysisRiskLevel.low => _ClauseFilter.low,
    AnalysisRiskLevel.missing => _ClauseFilter.missing,
    null => _ClauseFilter.all,
  };
  late String? _categoryFilter = widget.initialCategoryFilter;
  final _search = TextEditingController();
  final _expanded = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AnalysisClause> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return widget.result.clauses.where((c) {
      final levelOk = switch (_filter) {
        _ClauseFilter.all => true,
        _ClauseFilter.high => c.risk == AnalysisRiskLevel.high,
        _ClauseFilter.medium => c.risk == AnalysisRiskLevel.medium,
        _ClauseFilter.low => c.risk == AnalysisRiskLevel.low,
        _ClauseFilter.missing => c.risk == AnalysisRiskLevel.missing,
      };
      if (!levelOk) return false;
      // Category filter: only show clauses in the selected category
      if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
        final catOk = c.categories.any(
          (cat) => cat.toLowerCase() == _categoryFilter!.toLowerCase(),
        );
        if (!catOk) return false;
      }
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          c.originalText.toLowerCase().contains(q) ||
          c.plainEnglish.toLowerCase().contains(q);
    }).toList();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _openNotes(AnalysisClause c) async {
    final docId = widget.result.documentId;
    final clauseId = int.tryParse(c.id);
    if (docId == null || clauseId == null) {
      _toast('Notes need a saved analysis.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClauseNotesSheet(
        documentId: docId,
        clauseId: clauseId,
        clauseTitle: 'Clause ${c.number} — ${c.title}',
      ),
    );
  }

  Future<void> _flagClause(AnalysisClause c) async {
    final docId = widget.result.documentId;
    final clauseId = int.tryParse(c.id);
    if (docId == null || clauseId == null) {
      _toast('Flagging needs a saved analysis.');
      return;
    }
    try {
      await AnalysisRepository().riskFeedback(
        documentId: docId,
        clauseId: clauseId,
        feedbackType: 'mark_risky',
      );
      if (!mounted) return;
      _toast('Flagged for review.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final clauses = _filtered;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        foregroundColor: AppColors.primaryNavy,
        title: Text(
          'Clauses',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RiskDashboardPage(result: widget.result),
                ),
              );
            },
            child: Text(
              'Risks',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.primaryNavy,
              ),
              decoration: InputDecoration(
                hintText: 'Search clauses…',
                hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.inkSoft),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: AppColors.cloud,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in _ClauseFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(_filterLabel(f)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.primaryNavy,
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _filter == f
                            ? AppColors.cloud
                            : AppColors.primaryNavy,
                      ),
                      backgroundColor: AppColors.cloud,
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: AppColors.borderMuted),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: clauses.isEmpty
                ? Center(
                    child: Text(
                      'No clauses match.',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.inkSoft),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, AppInsets.shellBottom(context)),
                    itemCount: clauses.length,
                    itemBuilder: (context, index) {
                      final c = clauses[index];
                      final open = _expanded.contains(c.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SoftCard(
                          onTap: () {
                            setState(() {
                              if (open) {
                                _expanded.remove(c.id);
                              } else {
                                _expanded.add(c.id);
                              }
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Clause ${c.number} — ${c.title}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                  ),
                                  RiskChip(level: c.risk),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                c.originalText,
                                maxLines: open ? null : 3,
                                overflow: open
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              if (open) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Plain English',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c.plainEnglish,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => PlainLanguagePage(
                                            result: widget.result,
                                            initialClauseId: c.id,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'See Plain English',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _openNotes(c),
                                    child: Text(
                                      'Note',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _flagClause(c),
                                    child: Text(
                                      'Flag',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              ChatPage(result: widget.result),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Discuss',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(_ClauseFilter f) => switch (f) {
        _ClauseFilter.all => 'All',
        _ClauseFilter.high => 'High Risk',
        _ClauseFilter.medium => 'Medium',
        _ClauseFilter.low => 'Low',
        _ClauseFilter.missing => 'Missing',
      };
}

/// Bottom sheet: view / add / edit / delete notes on one clause.
class _ClauseNotesSheet extends StatefulWidget {
  const _ClauseNotesSheet({
    required this.documentId,
    required this.clauseId,
    required this.clauseTitle,
  });

  final int documentId;
  final int clauseId;
  final String clauseTitle;

  @override
  State<_ClauseNotesSheet> createState() => _ClauseNotesSheetState();
}

class _ClauseNotesSheetState extends State<_ClauseNotesSheet> {
  final _repo = FeaturesRepository();
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  String? _error;
  final _field = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notes = await _repo.listNotes(widget.documentId);
      if (!mounted) return;
      setState(() {
        _notes = notes
            .where((n) => n['clauseId'] == widget.clauseId)
            .toList();
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

  Future<void> _add() async {
    final text = _field.text.trim();
    if (text.isEmpty) return;
    try {
      await _repo.addNote(
        documentId: widget.documentId,
        clauseId: widget.clauseId,
        note: text,
      );
      _field.clear();
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _edit(Map<String, dynamic> note) async {
    final controller = TextEditingController(text: (note['note'] ?? '').toString());
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Note…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;
    final noteId = (note['id'] as num).toInt();
    try {
      await _repo.updateNote(noteId: noteId, note: text);
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _delete(Map<String, dynamic> note) async {
    final noteId = (note['id'] as num).toInt();
    try {
      await _repo.deleteNote(noteId);
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast(e.toString());
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.chip,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Notes',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.clauseTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.mute,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.error,
                          ),
                        ),
                      )
                    : _notes.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No notes yet. Add a reminder or question about this clause.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.mute,
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _notes.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final n = _notes[i];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (n['note'] ?? '').toString(),
                                        style:
                                            GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      color: AppColors.mute,
                                      onPressed: () => _edit(n),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      onPressed: () => _delete(n),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _field,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a note…',
                    hintStyle:
                        GoogleFonts.plusJakartaSans(color: AppColors.mute),
                    filled: true,
                    fillColor: AppColors.bg,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _add,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                child: const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
