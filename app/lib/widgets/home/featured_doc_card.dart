import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/dashboard_mock.dart';
import '../../theme/app_theme.dart';

/// Large featured document card — matches the Dribbble smart-home
/// device card pattern with image area, info, and status indicator.
class FeaturedDocCard extends StatelessWidget {
  const FeaturedDocCard({
    super.key,
    required this.document,
    required this.onTap,
  });

  final MockDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final risk = _riskStyle(document.risk);

    return Material(
      color: AppColors.cloud,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.rule),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.description_outlined,
                        size: 56,
                        color: AppColors.accentSky.withValues(alpha: 0.6),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: risk.bg,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          risk.label,
                          style: GoogleFonts.epilogue(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: risk.fg,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.epilogue(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.inkSoft.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          document.relativeDate,
                          style: GoogleFonts.epilogue(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paper2,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            document.typeLabel,
                            style: GoogleFonts.epilogue(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static ({String label, Color bg, Color fg}) _riskStyle(DocRisk risk) {
    return switch (risk) {
      DocRisk.low => (
          label: 'Low Risk',
          bg: const Color(0xFFE8F5EE),
          fg: const Color(0xFF1B6B3A),
        ),
      DocRisk.medium => (
          label: 'Medium',
          bg: const Color(0xFFFFF4E5),
          fg: const Color(0xFF9A5B00),
        ),
      DocRisk.high => (
          label: 'High Risk',
          bg: const Color(0xFFFDECEC),
          fg: AppColors.error,
        ),
    };
  }
}
