import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../mappers/analysis_mapper.dart';
import '../../models/api/analysis_models.dart';
import '../../repositories/documents_repository.dart';
import '../../services/api_exception.dart';
import '../../services/offline_cache.dart';
import '../../theme/app_theme.dart';
import 'analysis_results_page.dart';
import 'confirm_type_page.dart';

/// Loads live analysis for a document id, then opens the results hub.
class AnalysisLoaderPage extends StatefulWidget {
  const AnalysisLoaderPage({
    super.key,
    required this.documentId,
    this.titleHint,
  });

  final int documentId;
  final String? titleHint;

  @override
  State<AnalysisLoaderPage> createState() => _AnalysisLoaderPageState();
}

class _AnalysisLoaderPageState extends State<AnalysisLoaderPage> {
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final status = await DocumentsRepository().getStatus(widget.documentId);
      if (status.processingStatus == 'failed') {
        setState(() {
          _error =
              'We couldn’t analyze this document. Tap Retry to run analysis again.';
          _busy = false;
        });
        return;
      }
      if (status.processingStatus != 'analyzed') {
        // Kick off sync process instead of leaving user stuck.
        await _runProcess();
        return;
      }
      final bundle =
          await DocumentsRepository().getAnalysis(widget.documentId);
      await OfflineCache.saveAnalysis(widget.documentId, bundle);
      if (!bundle.hasAnalysis) {
        if (!mounted) return;
        final confirmed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ConfirmTypePage(documentId: widget.documentId),
          ),
        );
        if (confirmed == true && mounted) {
          final again =
              await DocumentsRepository().getAnalysis(widget.documentId);
          await OfflineCache.saveAnalysis(widget.documentId, again);
          if (!mounted) return;
          if (again.hasAnalysis) {
            _open(again);
            return;
          }
        }
        setState(() {
          _error = 'Analysis not ready yet.';
          _busy = false;
        });
        return;
      }
      if (!mounted) return;
      _open(bundle);
    } on ApiException catch (e) {
      await _fallbackToCache(e.message);
    } catch (e) {
      await _fallbackToCache(e.toString());
    }
  }

  /// When offline, open the last cached analysis for this document.
  Future<void> _fallbackToCache(String message) async {
    final cached = await OfflineCache.cachedAnalysis(widget.documentId);
    if (!mounted) return;
    if (cached != null && cached.hasAnalysis) {
      _open(cached);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Offline — showing the last saved analysis.'),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }
    setState(() {
      _error = message;
      _busy = false;
    });
  }

  Future<void> _runProcess() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final bundle =
          await DocumentsRepository().process(widget.documentId);
      await OfflineCache.saveAnalysis(widget.documentId, bundle);
      if (!mounted) return;
      if (!bundle.hasAnalysis) {
        setState(() {
          _error = 'Analysis returned empty. Try again.';
          _busy = false;
        });
        return;
      }
      _open(bundle);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.length > 120
            ? 'We couldn’t analyze this document. Please try again.'
            : e.message;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'We couldn’t analyze this document. Please try again.';
        _busy = false;
      });
    }
  }

  void _open(AnalysisBundle bundle) {
    final result = AnalysisMapper.fromBundle(
      bundle,
      documentId: widget.documentId,
      documentTitle: widget.titleHint,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AnalysisResultsPage(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          widget.titleHint ?? 'Loading analysis',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: _error == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.ink),
                  if (_busy) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing…',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.mute,
                      ),
                    ),
                  ],
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _runProcess,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
