import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../data/dashboard_mock.dart';
import '../../models/pending_upload.dart';
import '../../theme/app_theme.dart';
import '../analysis/analysis_stub_page.dart';

class ProcessingPage extends StatefulWidget {
  const ProcessingPage({super.key, required this.upload});

  final PendingUpload upload;

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  static const _steps = <String>[
    'Document received',
    'Format detected',
    'Extracting text…',
    'AI analyzing clauses…',
    'Generating risk score…',
    'Building your report…',
  ];

  static const _tips = <String>[
    'Tip: Ambiguous indemnity clauses often shift risk silently.',
    'Tip: Check notice periods before you sign a lease.',
    'Tip: “As is” language can limit remedies — read carefully.',
    'Fact: Many NDAs overreach on duration; 2–3 years is common.',
  ];

  int _completed = 0;
  int _secondsLeft = 12;
  late final String _tip;
  Timer? _stepTimer;
  Timer? _countdown;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _tip = _tips[DateTime.now().second % _tips.length];
    _start();
  }

  void _start() {
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _cancelled) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });

    _stepTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted || _cancelled) {
        t.cancel();
        return;
      }
      if (_completed >= _steps.length) {
        t.cancel();
        return;
      }
      setState(() => _completed += 1);
      if (_completed >= _steps.length) {
        t.cancel();
        Future<void>.delayed(const Duration(milliseconds: 450), _goToResults);
      }
    });
  }

  void _goToResults() {
    if (!mounted || _cancelled) return;
    final doc = MockDocument(
      id: 'upload-${DateTime.now().millisecondsSinceEpoch}',
      title: widget.upload.title,
      typeId: 'other',
      typeLabel: widget.upload.sourceLabel,
      risk: DocRisk.medium,
      relativeDate: 'Just now',
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AnalysisStubPage(document: doc),
      ),
    );
  }

  void _cancel() {
    _cancelled = true;
    _stepTimer?.cancel();
    _countdown?.cancel();
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.paper, AppColors.paper2],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _cancel,
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.epilogue(
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
                        const SizedBox(height: 8),
                        Text(
                          'Analyzing your document',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.epilogue(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.upload.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.epilogue(
                            fontSize: 14,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...List.generate(_steps.length, (i) {
                          final done = i < _completed;
                          final active =
                              i == _completed && _completed < _steps.length;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: done
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primaryNavy,
                                          size: 26,
                                        )
                                      : active
                                          ? const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: AppColors.accentSky,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.radio_button_unchecked,
                                              color: AppColors.progressIdle,
                                              size: 24,
                                            ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _steps[i],
                                    style: GoogleFonts.epilogue(
                                      fontSize: 15,
                                      fontWeight: done || active
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: done || active
                                          ? AppColors.primaryNavy
                                          : AppColors.inkSoft
                                              .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Spacer(),
                        const SizedBox(height: 16),
                        Text(
                          _secondsLeft > 0
                              ? 'About ${_secondsLeft}s remaining'
                              : 'Almost done…',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.epilogue(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cloud,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryNavy
                                    .withValues(alpha: 0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            _tip,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.epilogue(
                              fontSize: 13,
                              height: 1.45,
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
        ),
      ),
    );
  }
}
