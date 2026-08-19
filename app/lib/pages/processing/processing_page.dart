import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../models/pending_upload.dart';
import '../../models/api/analysis_models.dart';
import '../../mappers/analysis_mapper.dart';
import '../../repositories/documents_repository.dart';
import '../../services/api_exception.dart';
import '../../services/socket_service.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../analysis/analysis_results_page.dart';
import '../shell/main_shell.dart';

class ProcessingPage extends StatefulWidget {
  const ProcessingPage({super.key, required this.upload});

  final PendingUpload upload;

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  final _docs = DocumentsRepository();
  String _stage = 'Extracting text…';
  double _progress = 0.15;
  bool _cancelled = false;
  bool _finished = false;
  bool _analysisStarted = false;
  int _ocrFallbackPolls = 0;
  String? _error;
  Timer? _fakeProgress;
  Timer? _pollTimer;

  int? get _docId => widget.upload.documentId;

  /// Scan uploads run OCR through the backend queue worker — wait for
  /// `ocr:completed` (or `text_extracted` status) before running analysis.
  bool get _isScan => widget.upload.source == UploadSource.scan;

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

    final socket = SocketService.instance;
    await socket.connect();
    socket.subscribeDocument(id);
    void onProgress(dynamic data) {
      if (!mounted || _cancelled) return;
      if (data is Map) {
        final p = (data['progress'] as num?)?.toDouble();
        final stage = data['stage']?.toString();
        setState(() {
          if (p != null) _progress = (p / 100).clamp(0.05, 0.95);
          if (stage != null && stage.isNotEmpty) _stage = stage;
        });
      }
    }

    socket.on('analysis:progress', onProgress);

    // Scan uploads: OCR runs in the queue worker. When it finishes, the
    // backend fires 'ocr:completed' (or the status becomes 'text_extracted').
    void onOcrCompleted(dynamic data) {
      if (!mounted || _cancelled || _finished) return;
      if (data is Map && (data['documentId'] as num?)?.toInt() != id) return;
      _runAnalysis(id, socket);
    }

    void onOcrFailed(dynamic data) {
      if (!mounted || _cancelled) return;
      final message = data is Map ? data['error']?.toString() : null;
      setState(() => _error = message ?? 'OCR failed. Please retry.');
      _fakeProgress?.cancel();
    }

    if (_isScan) {
      socket.on('ocr:completed', onOcrCompleted);
      socket.on('ocr:failed', onOcrFailed);
      _stage = 'Running OCR on your scan…';
    }

    _fakeProgress = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted || _cancelled || _error != null || _finished) return;
      if (socket.isConnected && _progress > 0.2) return;
      setState(() {
        if (_progress < 0.85) {
          _progress = (_progress + 0.04).clamp(0.15, 0.85);
          if (_progress > 0.4 && _stage.startsWith('Extract')) {
            _stage = 'Analyzing with local AI…';
          }
        }
      });
    });

    // Status poll backup — also drives scan → analysis handoff if the socket
    // event was missed.
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _cancelled || _finished) {
        _pollTimer?.cancel();
        return;
      }
      try {
        final st = await _docs.getStatus(id);
        final label = st.processingStatus;
        if (label.isNotEmpty && mounted) {
          setState(() {
            _stage = label.replaceAll('_', ' ');
            final jp = st.job?['progress'];
            if (jp is num) {
              _progress = (jp / 100).clamp(0.05, 0.95);
            }
          });
        }
        if (_isScan && !_analysisStarted &&
            (label == 'text_extracted' || label == 'analyzed')) {
          _runAnalysis(id, socket);
        } else if (_isScan && !_analysisStarted && label == 'pending') {
          // Safety net: if the queue OCR job never ran (enqueue failed),
          // fall back to the sync path after ~24s so the user isn't stuck.
          _ocrFallbackPolls++;
          if (_ocrFallbackPolls >= 8) {
            _runAnalysis(id, socket);
          }
        }
      } catch (_) {}
    });

    if (_isScan) {
      // Wait for the queue worker — the socket event or poll drives analysis.
      setState(() {
        _stage = 'Running OCR on your scan…';
        _progress = 0.3;
      });
    } else {
      await _runAnalysis(id, socket);
    }
  }

  /// Runs the blocking process() and opens the results hub.
  Future<void> _runAnalysis(int id, SocketService socket) async {
    if (_analysisStarted || _cancelled || !mounted) return;
    _analysisStarted = true;
    try {
      setState(() {
        _stage = 'Analyzing with local AI…';
        _progress = 0.55;
      });

      final bundle = await _docs.process(id);
      if (_cancelled || !mounted) return;

      if (!bundle.hasAnalysis) {
        setState(() => _error = 'Analysis returned empty. Retry.');
        return;
      }

      await _openAnalysis(bundle);
    } on ApiException catch (e) {
      if (!mounted || _cancelled) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted || _cancelled) return;
      setState(() => _error = e.toString());
    } finally {
      _fakeProgress?.cancel();
      socket.off('analysis:progress');
      socket.off('ocr:completed');
      socket.off('ocr:failed');
      socket.unsubscribeDocument(id);
    }
  }

  Future<void> _openAnalysis(AnalysisBundle bundle) async {
    if (_cancelled || _finished || !mounted) return;
    _finished = true;
    _fakeProgress?.cancel();

    final id = _docId!;
    setState(() {
      _stage = 'Opening results…';
      _progress = 1;
    });

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
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _finished = false;
      _stage = 'Extracting text…';
      _progress = 0.15;
    });
    await _boot();
  }

  void _cancel() {
    _cancelled = true;
    _fakeProgress?.cancel();
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _fakeProgress?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, AppInsets.shellBottom(context)),
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
              const SizedBox(height: 18),
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.error),
                ),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton(
                    onPressed: _retry,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: _progress.clamp(0.05, 1),
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
      ),
    );
  }
}
