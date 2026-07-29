import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

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
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello $name',
            style: GoogleFonts.spectral(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AppColors.cloud,
              fontStyle: FontStyle.normal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ready to review a document?',
            style: GoogleFonts.epilogue(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: AppColors.cloud.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}
