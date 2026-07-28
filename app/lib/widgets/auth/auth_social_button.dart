import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../theme/app_theme.dart';

enum AuthSocialProvider { google, github, apple }

/// Circular social marks — inspiration row, not full-width slabs.
class AuthSocialRow extends StatelessWidget {
  const AuthSocialRow({
    super.key,
    required this.onGoogle,
    required this.onGithub,
    this.onApple,
  });

  final VoidCallback onGoogle;
  final VoidCallback onGithub;
  final VoidCallback? onApple;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialDisc(
          icon: FontAwesomeIcons.google,
          onTap: onGoogle,
        ),
        const SizedBox(width: 18),
        if (onApple != null) ...[
          _SocialDisc(
            icon: FontAwesomeIcons.apple,
            onTap: onApple!,
          ),
          const SizedBox(width: 18),
        ],
        _SocialDisc(
          icon: FontAwesomeIcons.github,
          onTap: onGithub,
        ),
      ],
    );
  }
}

class _SocialDisc extends StatelessWidget {
  const _SocialDisc({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cloud,
            border: Border.all(color: AppColors.borderMuted),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: FaIcon(icon, size: 18, color: AppColors.primaryNavy),
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
