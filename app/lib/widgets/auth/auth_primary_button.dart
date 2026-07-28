import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Pill CTA with trailing arrow disc — inspiration layout.
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
          height: 58,
          decoration: BoxDecoration(
            color: enabled ? AppColors.primaryNavy : AppColors.accentSoft,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primaryNavy.withValues(alpha: 0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: loading
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.cloud,
                            ),
                          ),
                        )
                      : Text(
                          label,
                          style: GoogleFonts.epilogue(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cloud,
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
                if (!loading)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.cloud,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primaryNavy,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
