import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repositories/features_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';

/// AI Playbook — save personal rules like "Never accept a non-compete > 1 year".
class PlaybookPage extends StatefulWidget {
  const PlaybookPage({super.key});

  @override
  State<PlaybookPage> createState() => _PlaybookPageState();
}

class _PlaybookPageState extends State<PlaybookPage> {
  final _repo = FeaturesRepository();
  List<Map<String, dynamic>> _rules = [];
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
      final rules = await _repo.playbookRules();
      if (!mounted) return;
      setState(() {
        _rules = rules;
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

  Future<void> _addRule() async {
    final text = await _promptForRule();
    if (text == null || text.trim().isEmpty || !mounted) return;
    try {
      await _repo.addPlaybookRule(ruleText: text.trim());
      if (!mounted) return;
      _toast('Rule saved.');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  Future<String?> _promptForRule([String? initial]) async {
    final controller = TextEditingController(text: initial ?? '');
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                initial == null ? 'New playbook rule' : 'Edit rule',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'e.g. Never accept a non-compete longer than 1 year',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.mute,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Your rule…',
                  hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.mute),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.field),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  'Save rule',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleRule(Map<String, dynamic> rule) async {
    final id = (rule['id'] as num?)?.toInt();
    if (id == null) return;
    final active = (rule['isActive'] as bool?) ?? true;
    try {
      await _repo.updatePlaybookRule(id: id, isActive: !active);
      if (!mounted) return;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  Future<void> _editRule(Map<String, dynamic> rule) async {
    final id = (rule['id'] as num?)?.toInt();
    if (id == null) return;
    final text = await _promptForRule(rule['ruleText'] as String?);
    if (text == null || text.trim().isEmpty || !mounted) return;
    try {
      await _repo.updatePlaybookRule(id: id, ruleText: text.trim());
      if (!mounted) return;
      _toast('Rule updated.');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  Future<void> _deleteRule(Map<String, dynamic> rule) async {
    final id = (rule['id'] as num?)?.toInt();
    if (id == null) return;
    try {
      await _repo.deletePlaybookRule(id);
      if (!mounted) return;
      _toast('Rule deleted.');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _rules.where((r) => (r['isActive'] as bool?) ?? true).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'AI Playbook',
              subtitle: '$active active rule${active == 1 ? '' : 's'}',
              leading: AppHeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              trailing: AppHeaderIconButton(
                icon: Icons.add_rounded,
                onTap: _addRule,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
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
                                  onPressed: _load,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _rules.isEmpty
                          ? _EmptyPlaybook(onAdd: _addRule)
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                8,
                                20,
                                AppInsets.shellBottom(context),
                              ),
                              itemCount: _rules.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final rule = _rules[i];
                                final isActive =
                                    (rule['isActive'] as bool?) ?? true;
                                return _RuleCard(
                                  rule: rule,
                                  onToggle: () => _toggleRule(rule),
                                  onEdit: () => _editRule(rule),
                                  onDelete: () => _deleteRule(rule),
                                  active: isActive,
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

class _EmptyPlaybook extends StatelessWidget {
  const _EmptyPlaybook({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded, size: 44, color: AppColors.mute),
            const SizedBox(height: 14),
            Text(
              'No rules yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Save your personal negotiation rules so they can guide every review.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.mute,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add your first rule'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.active,
  });

  final Map<String, dynamic> rule;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final category = (rule['category'] as String?) ?? 'general';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Opacity(
                  opacity: active ? 1 : 0.45,
                  child: Text(
                    rule['ruleText'] as String? ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              Switch(
                value: active,
                activeThumbColor: AppColors.ink,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.chip,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.mute,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
