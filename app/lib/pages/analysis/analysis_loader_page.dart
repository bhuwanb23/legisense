import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../mappers/analysis_mapper.dart';
import '../../repositories/documents_repository.dart';
import '../../services/api_exception.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await DocumentsRepository().getStatus(widget.documentId);
      if (status.processingStatus == 'failed') {
        setState(() => _error = 'Analysis failed for this document.');
        return;
      }
      if (status.processingStatus != 'analyzed') {
        // Still processing — show message
        setState(
          () => _error =
              'Document is still ${status.processingStatus}. Open Upload history later.',
        );
        return;
      }
      final bundle =
          await DocumentsRepository().getAnalysis(widget.documentId);
      if (!bundle.hasAnalysis) {
        // Might need type confirmation
        if (!mounted) return;
        final confirmed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ConfirmTypePage(documentId: widget.documentId),
          ),
        );
        if (confirmed == true && mounted) {
          final again =
              await DocumentsRepository().getAnalysis(widget.documentId);
          if (!mounted) return;
          if (again.hasAnalysis) {
            _open(again);
            return;
          }
        }
        setState(() => _error = 'Analysis not ready yet.');
        return;
      }
      if (!mounted) return;
      _open(bundle);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _open(dynamic bundle) {
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
            ? const CircularProgressIndicator()
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
                      onPressed: () {
                        setState(() => _error = null);
                        _load();
                      },
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
