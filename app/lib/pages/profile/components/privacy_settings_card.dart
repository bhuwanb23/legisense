import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_theme.dart';
import '../language/language_scope.dart';
import '../language/strings.dart';

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
    final controller = LanguageScope.of(context);
    final i18n = ProfileI18n.mapFor(controller.language);
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
              i18n['privacy.title'] ?? 'Privacy Settings',
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
                  label: i18n['privacy.profileVisibility'] ?? 'Profile Visibility',
                  value: profileVisibility,
                  valueColor: AppTheme.primaryBlue,
                  onTap: onProfileVisibilityTap,
                ),
                
                const SizedBox(height: AppTheme.spacingS),
                
                _buildPrivacyRow(
                  label: i18n['privacy.dataSharing'] ?? 'Data Sharing',
                  value: dataSharing,
                  valueColor: AppTheme.textSecondary,
                  onTap: onDataSharingTap,
                ),
                
                const SizedBox(height: AppTheme.spacingS),
                
                _buildPrivacyRow(
                  label: i18n['privacy.twoFactor'] ?? 'Two-Factor Auth',
                  value: twoFactorAuth ? (i18n['privacy.enabled'] ?? 'Enabled') : (i18n['privacy.disabled'] ?? 'Disabled'),
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
            Expanded(
              child: Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 14,
                      color: valueColor,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      style: AppTheme.bodySmall.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
