import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

enum AuthSocialProvider { google, github }

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.provider,
    required this.onPressed,
  });

  final AuthSocialProvider provider;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isGoogle = provider == AuthSocialProvider.google;
    final label = isGoogle ? 'Continue with Google' : 'Continue with GitHub';
    final icon = isGoogle ? FontAwesomeIcons.google : FontAwesomeIcons.github;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: AppColors.borderMuted),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.field),
          onTap: onPressed,
          child: SizedBox(
            height: AppSizes.socialButtonHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(icon, size: 18, color: AppColors.primaryNavy),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: GoogleFonts.epilogue(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
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

void showAuthComingSoon(BuildContext context, String provider) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$provider sign-in will connect with the backend soon.'),
      backgroundColor: AppColors.primaryNavy,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
