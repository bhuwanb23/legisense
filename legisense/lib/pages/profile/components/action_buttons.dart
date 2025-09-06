import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback? onEditProfile;
  final VoidCallback? onManagePrivacy;
  final VoidCallback? onLogout;
  final int delay;

  const ActionButtons({
    super.key,
    this.onEditProfile,
    this.onManagePrivacy,
    this.onLogout,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPrimaryButton(
                icon: FontAwesomeIcons.penToSquare,
                label: 'Edit Profile',
                onTap: onEditProfile,
                delay: delay,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPrimaryButton(
                icon: FontAwesomeIcons.shield,
                label: 'Manage Privacy',
                onTap: onManagePrivacy,
                delay: delay + 200,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (onLogout != null)
          _buildSecondaryButton(
            icon: FontAwesomeIcons.rightFromBracket,
            label: 'Logout',
            onTap: onLogout,
            delay: delay + 400,
          ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required int delay,
  }) {
    return Container(
      height: 56,
      decoration: AppTheme.primaryButtonDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  label,
                  style: AppTheme.buttonPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.9, 0.9),
          duration: AppTheme.animationMedium,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: AppTheme.animationSlow, delay: delay.ms);
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required int delay,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: const Color(0xFFFECACA),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: AppTheme.errorRed,
                  size: 18,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  label,
                  style: AppTheme.buttonPrimary.copyWith(
                    color: AppTheme.errorRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.9, 0.9),
          duration: AppTheme.animationMedium,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: AppTheme.animationSlow, delay: delay.ms);
  }
}
