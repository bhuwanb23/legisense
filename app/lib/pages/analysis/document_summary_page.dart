import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analysis/soft_card.dart';
import '../chat/chat_page.dart';
import 'clause_breakdown_page.dart';

/// Full document summary — dense letter-stack layout.
class DocumentSummaryPage extends StatelessWidget {
  const DocumentSummaryPage({super.key, required this.result});

  final AnalysisResult result;

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          'Document summary',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          _SectionLabel('Overview'),
          SoftCard(
            child: Text(
              result.overview,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.45,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SectionLabel('Key parties'),
          ...result.parties.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      p.role,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mute,
                      ),
                    ),
                    if (p.obligations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...p.obligations.map(
                        (o) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '·  ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.ink,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  o,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _SectionLabel('Critical dates'),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < result.criticalDates.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.criticalDates[i].label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                        Text(
                          result.criticalDates[i].value,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < result.criticalDates.length - 1)
                    const Divider(height: 1, color: AppColors.rule),
                ],
              ],
            ),
          ),
          if (result.breachScenarios.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionLabel('What happens if…'),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < result.breachScenarios.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == result.breachScenarios.length - 1 ? 0 : 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppColors.riskMedium,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.breachScenarios[i],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                height: 1.4,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ClauseBreakdownPage(result: result),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.rule),
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
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
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatPage(result: result),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
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
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _toast(context, 'Export comes with backend.'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.rule),
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                  child: Text(
                    'Export',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
