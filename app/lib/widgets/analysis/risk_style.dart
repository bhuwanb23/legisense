import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../theme/app_theme.dart';

abstract final class RiskStyle {
  static Color color(AnalysisRiskLevel level) => switch (level) {
        AnalysisRiskLevel.low => AppColors.riskLow,
        AnalysisRiskLevel.medium => AppColors.riskMedium,
        AnalysisRiskLevel.high => AppColors.riskHigh,
        AnalysisRiskLevel.missing => AppColors.riskMissing,
      };

  static Color background(AnalysisRiskLevel level) => switch (level) {
        AnalysisRiskLevel.low => AppColors.riskLowBg,
        AnalysisRiskLevel.medium => AppColors.riskMediumBg,
        AnalysisRiskLevel.high => AppColors.riskHighBg,
        AnalysisRiskLevel.missing => AppColors.riskMissingBg,
      };

  static String label(AnalysisRiskLevel level) => switch (level) {
        AnalysisRiskLevel.low => 'LOW',
        AnalysisRiskLevel.medium => 'MEDIUM',
        AnalysisRiskLevel.high => 'HIGH',
        AnalysisRiskLevel.missing => 'MISSING',
      };

  static Color scoreColor(int score) {
    if (score <= 33) return AppColors.riskLow;
    if (score <= 66) return AppColors.riskMedium;
    return AppColors.riskHigh;
  }

  static AnalysisRiskLevel bandForScore(int score) {
    if (score <= 33) return AnalysisRiskLevel.low;
    if (score <= 66) return AnalysisRiskLevel.medium;
    return AnalysisRiskLevel.high;
  }
}

class RiskChip extends StatelessWidget {
  const RiskChip({super.key, required this.level});

  final AnalysisRiskLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: RiskStyle.background(level),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        RiskStyle.label(level),
        style: GoogleFonts.epilogue(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: RiskStyle.color(level),
        ),
      ),
    );
  }
}
