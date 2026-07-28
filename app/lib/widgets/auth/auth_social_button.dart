import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

enum AuthSocialProvider { google, facebook, apple }

/// Pill-shaped social login buttons — matches the Dribbble inspiration
/// with Google + Facebook labels and icons.
class AuthSocialRow extends StatelessWidget {
  const AuthSocialRow({
    super.key,
    required this.onGoogle,
    required this.onFacebook,
    this.onApple,
  });

  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  final VoidCallback? onApple;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SocialPill(
          icon: FontAwesomeIcons.google,
          label: 'Google',
          onTap: onGoogle,
        ),
        const SizedBox(height: 12),
        _SocialPill(
          icon: FontAwesomeIcons.facebookF,
          label: 'Facebook',
          onTap: onFacebook,
        ),
        if (onApple != null) ...[
          const SizedBox(height: 12),
          _SocialPill(
            icon: FontAwesomeIcons.apple,
            label: 'Apple',
            onTap: onApple!,
          ),
        ],
      ],
    );
  }
}

class _SocialPill extends StatelessWidget {
  const _SocialPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.cloud,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: AppColors.borderMuted.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 18, color: AppColors.primaryNavy),
              const SizedBox(width: 10),
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
    );
  }
}

void showAuthComingSoon(BuildContext context, String provider) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$provider sign-in comes with the backend.'),
      backgroundColor: AppColors.primaryNavy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
