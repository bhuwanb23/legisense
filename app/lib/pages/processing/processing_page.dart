import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../models/pending_upload.dart';
import '../../mappers/analysis_mapper.dart';
import '../../repositories/documents_repository.dart';
import '../../services/api_exception.dart';
import '../../services/socket_service.dart';
import '../../theme/app_theme.dart';
import '../analysis/analysis_results_page.dart';
import '../analysis/confirm_type_page.dart';
import '../shell/main_shell.dart';

class ProcessingPage extends StatefulWidget {
  const ProcessingPage({super.key, required this.upload});

  final PendingUpload upload;

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  final _docs = DocumentsRepository();
  String _stage = 'Starting…';
  int _progress = 5;
  bool _cancelled = false;
  bool _finished = false;
  Timer? _poll;
  String? _error;

  int? get _docId => widget.upload.documentId;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final id = _docId;
    if (id == null) {
      setState(() => _error = 'Missing document id. Upload again.');
      return;
    }
    await SocketService.instance.connect();
    SocketService.instance.subscribeDocument(id);
    SocketService.instance.on('ocr:progress', _onOcrProgress);
    SocketService.instance.on('ocr:completed', _onOcrDone);
    SocketService.instance.on('analysis:progress', _onAnalysisProgress);
    SocketService.instance.on('analysis:completed', _onAnalysisDone);
    SocketService.instance.on('analysis:failed', _onFailed);
    SocketService.instance.on('ocr:failed', _onFailed);
    SocketService.instance.on('analysis:needs_confirmation', _onNeedsConfirm);

    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
    await _checkStatus();
  }

  void _onOcrProgress(dynamic data) {
    if (!mounted || _cancelled) return;
    final m = data is Map ? Map<String, dynamic>.from(data) : {};
    setState(() {
      _stage = 'OCR: ${m['stage'] ?? 'extracting'}';
      _progress = (m['progress'] as num?)?.toInt() ?? _progress;
    });
  }

  void _onOcrDone(dynamic _) {
    if (!mounted || _cancelled) return;
    setState(() {
      _stage = 'OCR complete — starting analysis…';
      _progress = 40;
    });
  }

  void _onAnalysisProgress(dynamic data) {
    if (!mounted || _cancelled) return;
    final m = data is Map ? Map<String, dynamic>.from(data) : {};
    setState(() {
      _stage = 'Analysis: ${m['stage'] ?? 'running'}';
      final p = (m['progress'] as num?)?.toInt();
      if (p != null) _progress = 40 + (p * 0.55).round();
    });
  }

  Future<void> _onAnalysisDone(dynamic _) async {
    await _finish();
  }

  void _onFailed(dynamic data) {
    if (!mounted || _cancelled) return;
    final m = data is Map ? Map<String, dynamic>.from(data) : {};
    setState(() => _error = m['error']?.toString() ?? 'Processing failed');
  }

  Future<void> _onNeedsConfirm(dynamic _) async {
    if (!mounted || _cancelled) return;
    final id = _docId!;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ConfirmTypePage(documentId: id)),
    );
    if (ok == true) await _checkStatus();
  }

  Future<void> _checkStatus() async {
    final id = _docId;
    if (id == null || _cancelled) return;
    try {
      final status = await _docs.getStatus(id);
      if (!mounted) return;
      setState(() {
        _stage = 'Status: ${status.processingStatus}';
        if (status.processingStatus == 'ocr_processing') _progress = 25;
        if (status.processingStatus == 'processing') _progress = 60;
      });
      if (status.processingStatus == 'analyzed') {
        await _finish();
      } else if (status.processingStatus == 'failed') {
        setState(() => _error = 'Analysis failed');
      }
    } catch (_) {}
  }

  Future<void> _finish() async {
    if (_cancelled || _finished || !mounted) return;
    _finished = true;
    _poll?.cancel();
    final id = _docId!;
    try {
      final bundle = await _docs.getAnalysis(id);
      if (!bundle.hasAnalysis) {
        _finished = false;
        setState(() => _stage = 'Waiting for analysis payload…');
        return;
      }
      if (!mounted || _cancelled) return;
      final result = AnalysisMapper.fromBundle(
        bundle,
        documentId: id,
        documentTitle: widget.upload.title,
      );
      final shell = ShellScope.maybeOf(context);
      if (shell != null) {
        shell.openAnalysisOnDocuments(result);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => AnalysisResultsPage(result: result),
          ),
          (route) => route.isFirst,
        );
      }
    } on ApiException catch (e) {
      _finished = false;
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  void _cancel() {
    _cancelled = true;
    _poll?.cancel();
    final id = _docId;
    if (id != null) SocketService.instance.unsubscribeDocument(id);
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _poll?.cancel();
    final id = _docId;
    if (id != null) {
      SocketService.instance.off('ocr:progress');
      SocketService.instance.off('ocr:completed');
      SocketService.instance.off('analysis:progress');
      SocketService.instance.off('analysis:completed');
      SocketService.instance.off('analysis:failed');
      SocketService.instance.off('ocr:failed');
      SocketService.instance.off('analysis:needs_confirmation');
      SocketService.instance.unsubscribeDocument(id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _cancel,
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: Lottie.asset(
                  'assets/lottie/logo_splash.json',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Analyzing your document',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.upload.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: AppColors.mute),
              ),
              const SizedBox(height: 28),
              if (_error != null)
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.error),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: (_progress.clamp(0, 100)) / 100,
                    minHeight: 10,
                    backgroundColor: AppColors.chip,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _stage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.mute,
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
