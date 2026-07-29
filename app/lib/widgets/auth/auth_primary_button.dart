import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Ink pill CTA — Spectral label.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: enabled ? onPressed : null,
        child: Ink(
          height: AppSizes.buttonHeight,
          decoration: BoxDecoration(
            color: enabled ? AppColors.ink : AppColors.paper2,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.cloud,
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.spectral(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppColors.cloud : AppColors.inkSoft,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
