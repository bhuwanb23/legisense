import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../data/legal_glossary.dart';
import '../../repositories/analysis_repository.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analysis/soft_card.dart';
import '../chat/chat_page.dart';
import 'clause_breakdown_page.dart';

enum _ViewMode { stacked, flip }

enum _ReadingLevel { grade5, grade8, standard }

/// Page 17 — Legalese decoder / plain language translator.
class PlainLanguagePage extends StatefulWidget {
  const PlainLanguagePage({
    super.key,
    required this.result,
    this.initialClauseId,
  });

  final AnalysisResult result;
  final String? initialClauseId;

  @override
  State<PlainLanguagePage> createState() => _PlainLanguagePageState();
}

class _PlainLanguagePageState extends State<PlainLanguagePage> {
  bool _showOriginal = true;
  _ViewMode _mode = _ViewMode.stacked;
  _ReadingLevel _level = _ReadingLevel.grade8;
  bool _rewriting = false;
  final Map<String, String> _rewrittenPlain = {};

  List<AnalysisClause> get _clauses => widget.result.clauses
      .where((c) => c.risk != AnalysisRiskLevel.missing)
      .toList();

  Future<void> _setReadingLevel(_ReadingLevel level) async {
    setState(() => _level = level);
    final docId = widget.result.documentId;
    if (docId == null) return;
    setState(() => _rewriting = true);
    try {
      final levelKey = switch (level) {
        _ReadingLevel.grade5 => 'grade5',
        _ReadingLevel.grade8 => 'grade8',
        _ReadingLevel.standard => 'standard',
      };
      final data = await AnalysisRepository().rewritePlainEnglish(
        docId,
        readingLevel: levelKey,
      );
      final raw = data['clauses'] ?? data['items'] ?? data['plainEnglish'];
      if (raw is List) {
        for (final item in raw) {
          if (item is! Map) continue;
          final id = item['id']?.toString() ??
              item['clauseId']?.toString() ??
              '';
          final plain = item['plainEnglish']?.toString() ??
              item['plain_english']?.toString() ??
              item['text']?.toString();
          if (id.isNotEmpty && plain != null) {
            _rewrittenPlain[id] = plain;
          }
        }
      }
      if (mounted) setState(() {});
    } catch (_) {
      // Keep local fallback via _plainForLevel.
    } finally {
      if (mounted) setState(() => _rewriting = false);
    }
  }

  String _displayPlain(AnalysisClause c) {
    return _rewrittenPlain[c.id] ?? _plainForLevel(c.plainEnglish);
  }

  Future<void> _lookupAndShow(String term, [String? fallback]) async {
    var definition = fallback ?? LegalGlossary.terms[term] ??
        LegalGlossary.terms[term.toLowerCase()];
    try {
      final data = await AnalysisRepository().glossary(term);
      final apiDef = data['definition']?.toString();
      if (apiDef != null && apiDef.isNotEmpty) {
        definition = apiDef;
      }
    } catch (_) {
      // Keep local fallback.
    }
    if (!mounted) return;
    _showDefinition(term, definition ?? 'No definition found for “$term”.');
  }

  void _showDefinition(String term, String definition) {
    // Root navigator so the sheet sits above the floating shell dock.
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  term,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  definition,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openGlossaryList() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scroll) {
            final entries = LegalGlossary.terms.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));
            return SafeArea(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  Text(
                    'Legal glossary',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap a highlighted word in the original text, or browse here.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...entries.map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        e.key,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      subtitle: Text(
                        e.value,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _lookupAndShow(e.key, e.value);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  TextSpan _glossarySpan(String text) {
    final lower = text.toLowerCase();
    final spans = <InlineSpan>[];
    var i = 0;
    final baseStyle = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      height: 1.5,
      color: AppColors.inkSoft,
    );
    final linkStyle = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w700,
      color: AppColors.primaryNavy,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.accentSky,
    );

    while (i < text.length) {
      MapEntry<String, String>? hit;
      for (final e in LegalGlossary.sortedEntries) {
        final key = e.key.toLowerCase();
        if (i + key.length > lower.length) continue;
        if (lower.substring(i, i + key.length) != key) continue;
        final beforeOk = i == 0 || !_isWordChar(lower[i - 1]);
        final afterOk = i + key.length >= lower.length ||
            !_isWordChar(lower[i + key.length]);
        if (beforeOk && afterOk) {
          hit = e;
          break;
        }
      }
      if (hit == null) {
        final next = _nextGlossaryIndex(lower, i);
        spans.add(TextSpan(
          text: text.substring(i, next),
          style: baseStyle,
        ));
        i = next;
        continue;
      }
      final term = text.substring(i, i + hit.key.length);
      final termKey = hit.key;
      final definition = hit.value;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => _lookupAndShow(termKey, definition),
            child: Text(term, style: linkStyle),
          ),
        ),
      );
      i += termKey.length;
    }

    return TextSpan(children: spans);
  }

  int _nextGlossaryIndex(String lower, int from) {
    var best = lower.length;
    for (final e in LegalGlossary.sortedEntries) {
      final key = e.key.toLowerCase();
      var search = from + 1;
      while (true) {
        final idx = lower.indexOf(key, search);
        if (idx < 0) break;
        final beforeOk = idx == 0 || !_isWordChar(lower[idx - 1]);
        final afterOk = idx + key.length >= lower.length ||
            !_isWordChar(lower[idx + key.length]);
        if (beforeOk && afterOk && idx < best) {
          best = idx;
          break;
        }
        search = idx + 1;
      }
    }
    return best;
  }

  bool _isWordChar(String ch) => RegExp(r'[a-zA-Z]').hasMatch(ch);

  String _plainForLevel(String plain) {
    return switch (_level) {
      _ReadingLevel.grade5 => plain
          .replaceAll('indemnify', 'cover the cost for')
          .replaceAll('premises', 'home')
          .replaceAll('vacating', 'moving out'),
      _ReadingLevel.grade8 => plain,
      _ReadingLevel.standard =>
        '$plain (Standard reading — closer to the legal wording.)',
    };
  }

  @override
  Widget build(BuildContext context) {
    final clauses = _clauses;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        foregroundColor: AppColors.primaryNavy,
        title: Text(
          'Plain language',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _openGlossaryList,
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: AppColors.borderMuted),
                  ),
                  child: Row(
                    children: [
                      _ToggleHalf(
                        label: 'Original',
                        selected: _showOriginal,
                        onTap: () => setState(() => _showOriginal = true),
                      ),
                      _ToggleHalf(
                        label: 'Plain English',
                        selected: !_showOriginal,
                        onTap: () => setState(() => _showOriginal = false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ModeChip(
                      label: 'Stacked',
                      selected: _mode == _ViewMode.stacked,
                      onTap: () => setState(() => _mode = _ViewMode.stacked),
                    ),
                    const SizedBox(width: 8),
                    _ModeChip(
                      label: 'Flip',
                      selected: _mode == _ViewMode.flip,
                      onTap: () => setState(() => _mode = _ViewMode.flip),
                    ),
                    const Spacer(),
                    PopupMenuButton<_ReadingLevel>(
                      initialValue: _level,
                      onSelected: _setReadingLevel,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: _ReadingLevel.grade5,
                          child: Text('Grade 5'),
                        ),
                        PopupMenuItem(
                          value: _ReadingLevel.grade8,
                          child: Text('Grade 8'),
                        ),
                        PopupMenuItem(
                          value: _ReadingLevel.standard,
                          child: Text('Standard'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.riskLowBg,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_rewriting) ...[
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              switch (_level) {
                                _ReadingLevel.grade5 => 'Grade 5',
                                _ReadingLevel.grade8 => 'Grade 8',
                                _ReadingLevel.standard => 'Standard',
                              },
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.riskLow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    // Action bar (~64) + air above dock.
                    64 + AppInsets.footerAboveDock(context),
                  ),
                  itemCount: clauses.length,
                  itemBuilder: (context, index) {
                    final c = clauses[index];
                    final highlight = c.id == widget.initialClauseId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SoftCard(
                        padding: EdgeInsets.zero,
                        child: Container(
                          decoration: highlight
                              ? BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.md),
                                  border: Border.all(
                                    color: AppColors.accentSky,
                                    width: 1.5,
                                  ),
                                )
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_mode == _ViewMode.stacked ||
                                  _showOriginal)
                                _SectionBlock(
                                  title: 'ORIGINAL (Legal)',
                                  titleColor: AppColors.inkSoft,
                                  child: Text.rich(
                                    _glossarySpan(c.originalText),
                                  ),
                                ),
                              if (_mode == _ViewMode.stacked)
                                const Divider(
                                  height: 1,
                                  color: AppColors.borderMuted,
                                ),
                              if (_mode == _ViewMode.stacked ||
                                  !_showOriginal)
                                _SectionBlock(
                                  title: 'PLAIN ENGLISH',
                                  titleColor: AppColors.riskLow,
                                  trailing: const Text('🟢'),
                                  child: Text(
                                    _displayPlain(c),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 0, 14, 10),
                                child: Text(
                                  'Clause ${c.number} — ${c.title}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppInsets.footerAboveDock(context),
                  child: Material(
                    color: AppColors.paper,
                    elevation: 0,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.rule),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ClauseBreakdownPage(
                                        result: widget.result,
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.ink,
                                  side:
                                      const BorderSide(color: AppColors.rule),
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.pill,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Clauses',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          ChatPage(result: widget.result),
                                    ),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.ink,
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.pill,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Chat',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleHalf extends StatelessWidget {
  const _ToggleHalf({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.primaryNavy : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.cloud : AppColors.inkSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accentSoft,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: AppColors.primaryNavy,
      ),
      backgroundColor: AppColors.cloud,
      side: const BorderSide(color: AppColors.borderMuted),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.titleColor,
    required this.child,
    this.trailing,
  });

  final String title;
  final Color titleColor;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: titleColor,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
