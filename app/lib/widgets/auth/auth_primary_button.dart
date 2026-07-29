import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.showArrow = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool showArrow;

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
            color: enabled ? AppColors.ink : AppColors.chip,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: enabled ? AppShadows.soft : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.surface,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: enabled ? AppColors.surface : AppColors.mute,
                          ),
                        ),
                      ),
                      if (showArrow)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: enabled ? AppColors.ink : AppColors.mute,
                            size: 20,
                          ),
                        )
                      else
                        const SizedBox(width: 16),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
