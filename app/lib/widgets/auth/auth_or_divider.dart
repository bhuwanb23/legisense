import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({
    super.key,
    this.label = 'or continue with',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.borderMuted, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: GoogleFonts.epilogue(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft.withValues(alpha: 0.75),
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.borderMuted, thickness: 1),
        ),
      ],
    );
  }
}
