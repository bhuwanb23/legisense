import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_theme.dart';

class PrivacySettingsCard extends StatelessWidget {
  final String profileVisibility;
  final String dataSharing;
  final bool twoFactorAuth;
  final VoidCallback? onProfileVisibilityTap;
  final VoidCallback? onDataSharingTap;
  final VoidCallback? onTwoFactorAuthTap;

  const PrivacySettingsCard({
    super.key,
    required this.profileVisibility,
    required this.dataSharing,
    required this.twoFactorAuth,
    this.onProfileVisibilityTap,
    this.onDataSharingTap,
    this.onTwoFactorAuthTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              'Privacy Settings',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              children: [
                _buildPrivacyRow(
                  label: 'Profile Visibility',
                  value: profileVisibility,
                  valueColor: AppTheme.primaryBlue,
                  onTap: onProfileVisibilityTap,
                ),
                
                const SizedBox(height: AppTheme.spacingS),
                
                _buildPrivacyRow(
                  label: 'Data Sharing',
                  value: dataSharing,
                  valueColor: AppTheme.textSecondary,
                  onTap: onDataSharingTap,
                ),
                
                const SizedBox(height: AppTheme.spacingS),
                
                _buildPrivacyRow(
                  label: 'Two-Factor Auth',
                  value: twoFactorAuth ? 'Enabled' : 'Disabled',
                  valueColor: twoFactorAuth ? AppTheme.successGreen : AppTheme.textSecondary,
                  icon: twoFactorAuth ? FontAwesomeIcons.circleCheck : null,
                  onTap: onTwoFactorAuthTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyRow({
    required String label,
    required String value,
    required Color valueColor,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: valueColor,
                  ),
                  const SizedBox(width: AppTheme.spacingXS),
                ],
                Text(
                  value,
                  style: AppTheme.bodySmall.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
