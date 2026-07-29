import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analysis/soft_card.dart';
import '../chat/chat_page.dart';
import 'clause_breakdown_page.dart';

/// Page 14 — Full document summary.
class DocumentSummaryPage extends StatelessWidget {
  const DocumentSummaryPage({super.key, required this.result});

  final AnalysisResult result;

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        foregroundColor: AppColors.primaryNavy,
        title: Text(
          'Document summary',
          style: GoogleFonts.epilogue(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Overview',
            style: GoogleFonts.epilogue(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 10),
          SoftCard(
            child: Text(
              result.overview,
              style: GoogleFonts.epilogue(
                fontSize: 14,
                height: 1.55,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Key parties',
            style: GoogleFonts.epilogue(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 10),
          ...result.parties.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.epilogue(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    Text(
                      p.role,
                      style: GoogleFonts.epilogue(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentSky,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...p.obligations.map(
                      (o) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  ',
                                style: TextStyle(color: AppColors.primaryNavy)),
                            Expanded(
                              child: Text(
                                o,
                                style: GoogleFonts.epilogue(
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
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Critical dates',
            style: GoogleFonts.epilogue(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 10),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < result.criticalDates.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.criticalDates[i].label,
                            style: GoogleFonts.epilogue(
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                        Text(
                          result.criticalDates[i].value,
                          style: GoogleFonts.epilogue(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < result.criticalDates.length - 1)
                    const Divider(height: 1, color: AppColors.borderMuted),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'What happens if…',
            style: GoogleFonts.epilogue(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 10),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.breachScenarios
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: AppColors.riskMedium,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s,
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
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Clause breakdown'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ClauseBreakdownPage(result: result),
                    ),
                  );
                },
              ),
              ActionChip(
                label: const Text('Chat'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatPage(result: result),
                    ),
                  );
                },
              ),
              ActionChip(
                label: const Text('Export'),
                onPressed: () =>
                    _toast(context, 'Export comes with backend.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
