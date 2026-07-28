import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Compact stat card for the 2x2 grid — matches the Dribbble
/// device card pattern with icon, value, and label.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent
                  ? AppColors.brightBlue.withValues(alpha: 0.12)
                  : AppColors.skyWash,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: accent ? AppColors.brightBlue : AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.epilogue(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.epilogue(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
