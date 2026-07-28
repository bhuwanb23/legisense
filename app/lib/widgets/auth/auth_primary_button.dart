import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? AppColors.primaryNavy : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: AppSizes.buttonHeight,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cloud,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
