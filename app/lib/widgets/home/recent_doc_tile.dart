import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/dashboard_mock.dart';
import '../../theme/app_theme.dart';

class RecentDocTile extends StatelessWidget {
  const RecentDocTile({
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
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primaryNavy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.epilogue(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${document.typeLabel} · ${document.relativeDate}',
                      style: GoogleFonts.epilogue(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            ],
          ),
        ),
      ),
    );
  }

  static ({String label, Color bg, Color fg}) _riskStyle(DocRisk risk) {
    return switch (risk) {
      DocRisk.low => (
          label: 'Low',
          bg: const Color(0xFFE8F5EE),
          fg: const Color(0xFF1B6B3A),
        ),
      DocRisk.medium => (
          label: 'Medium',
          bg: const Color(0xFFFFF4E5),
          fg: const Color(0xFF9A5B00),
        ),
      DocRisk.high => (
          label: 'High',
          bg: const Color(0xFFFDECEC),
          fg: AppColors.error,
        ),
    };
  }
}
