import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repositories/analysis_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';

class ConfirmTypePage extends StatefulWidget {
  const ConfirmTypePage({super.key, required this.documentId});

  final int documentId;

  @override
  State<ConfirmTypePage> createState() => _ConfirmTypePageState();
}

class _ConfirmTypePageState extends State<ConfirmTypePage> {
  Map<String, dynamic>? _data;
  String? _selected;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AnalysisRepository().classify(widget.documentId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _selected = data['type'] as String?;
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

  Future<void> _confirm() async {
    final type = _selected;
    if (type == null) return;
    setState(() => _saving = true);
    try {
      await AnalysisRepository().confirmType(widget.documentId, type);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = (_data?['supportedTypes'] as List?) ?? [];
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Confirm document type',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, AppInsets.shellBottom(context)),
                  children: [
                    Text(
                      _data?['typeLabel'] as String? ??
                          'We detected a document type',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Confidence: ${((_data?['confidence'] as num?)?.toDouble() ?? 0) * 100 ~/ 1}%',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.mute),
                    ),
                    const SizedBox(height: 20),
                    ...types.map((t) {
                      final map = t is Map
                          ? Map<String, dynamic>.from(t)
                          : <String, dynamic>{'type': t.toString()};
                      final id = map['type']?.toString() ?? map['id']?.toString();
                      final label =
                          map['typeLabel']?.toString() ?? map['label']?.toString() ?? id;
                      return RadioListTile<String>(
                        value: id ?? '',
                        groupValue: _selected,
                        title: Text(label ?? ''),
                        onChanged: (v) => setState(() => _selected = v),
                      );
                    }),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _saving ? null : _confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Confirm type',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
