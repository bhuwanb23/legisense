import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repositories/features_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';

/// One-click "Better Version" — AI rewrite of the whole document into a
/// fairer, more balanced version.
class BetterVersionPage extends StatefulWidget {
  const BetterVersionPage({super.key, required this.documentId});

  final int documentId;

  @override
  State<BetterVersionPage> createState() => _BetterVersionPageState();
}

class _BetterVersionPageState extends State<BetterVersionPage> {
  final _repo = FeaturesRepository();
  bool _loading = false;
  bool _started = false;
  String? _error;
  Map<String, dynamic>? _result;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.betterVersion(widget.documentId);
      if (!mounted) return;
      setState(() {
        _result = result;
        _started = true;
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

  @override
  Widget build(BuildContext context) {
    final rewritten = (_result?['rewrittenText'] ?? '').toString();
    final rawChanges = _result?['changes'];
    final changes = rawChanges is List
        ? rawChanges.map((c) => c.toString()).where((c) => c.trim().isNotEmpty).toList()
        : <String>[];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          'Better Version',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, AppInsets.shellBottom(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 26),
                    const SizedBox(height: 10),
                    Text(
                      'One-click fairer rewrite',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ask AI to rewrite the whole document into a more balanced version — neutralizing one-sided terms while keeping every clause.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _loading ? null : _generate,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.ink,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.ink,
                              ),
                            )
                          : const Icon(Icons.auto_fix_high_rounded, size: 18),
                      label: Text(
                        _loading
                            ? 'Rewriting…'
                            : _started
                                ? 'Rewrite again'
                                : 'Generate better version',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.error),
                ),
              ],
              if (rewritten.isNotEmpty) ...[
                const SizedBox(height: 20),
                if (changes.isNotEmpty) ...[
                  Text(
                    'What changed',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...changes.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: Color(0xFF22C55E)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Rewritten document',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Text(
                    rewritten,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    final text = rewritten;
                    final controller = TextEditingController(text: text);
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Rewritten document'),
                        content: SizedBox(
                          width: double.maxFinite,
                          height: 320,
                          child: TextField(
                            controller: controller,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: controller.text),
                              );
                              Navigator.pop(context);
                              _toast('Copied to clipboard.');
                            },
                            child: const Text('Copy'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  label: Text(
                    'Copy rewritten text',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
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
