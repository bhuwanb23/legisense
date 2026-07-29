import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Shared paper chrome — unused in TripGlide home (kept for compatibility).
class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello $name',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.surface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ready to review a document?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.surface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
