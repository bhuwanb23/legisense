import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

enum AuthSocialProvider { google, facebook, apple }

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
    return Row(
      children: [
        Expanded(child: _SocialDisc(icon: FontAwesomeIcons.google, onTap: onGoogle)),
        const SizedBox(width: 12),
        Expanded(child: _SocialDisc(icon: FontAwesomeIcons.facebookF, onTap: onFacebook)),
        if (onApple != null) ...[
          const SizedBox(width: 12),
          Expanded(child: _SocialDisc(icon: FontAwesomeIcons.apple, onTap: onApple!)),
        ],
      ],
    );
  }
}

class _SocialDisc extends StatelessWidget {
  const _SocialDisc({required this.icon, required this.onTap});

  final FaIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: AppShadows.soft,
          ),
          child: Center(
            child: FaIcon(icon, size: 18, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

void showAuthComingSoon(BuildContext context, String provider) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '$provider sign-in comes with the backend.',
        style: GoogleFonts.plusJakartaSans(),
      ),
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
