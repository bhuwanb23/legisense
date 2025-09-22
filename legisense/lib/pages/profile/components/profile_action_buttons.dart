import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../language/language_scope.dart';
import '../language/strings.dart';

class ProfileActionButtons extends StatelessWidget {
  final VoidCallback? onEditProfile;
  final VoidCallback? onManagePrivacy;
  final VoidCallback? onLogout;

  const ProfileActionButtons({
    super.key,
    this.onEditProfile,
    this.onManagePrivacy,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final controller = LanguageScope.of(context);
    final i18n = ProfileI18n.mapFor(controller.language);
    return Column(
      children: [
        // Edit Profile Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3B82F6), // blue-500
                  Color(0xFFA78BFA), // violet-400
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onEditProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              child: Text(
                i18n['actions.editProfile'] ?? 'Edit Profile',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingS),
        
        // Manage Privacy Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: onManagePrivacy,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              side: BorderSide(
                color: AppTheme.primaryBlue.withValues(alpha: 0.6),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  i18n['actions.managePrivacy'] ?? 'Manage Privacy',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        if (onLogout != null) ...[
          const SizedBox(height: AppTheme.spacingS),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: BorderSide(
                  color: AppTheme.errorRed.withValues(alpha: 0.7),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              child: Text(
                i18n['actions.logout'] ?? 'Logout',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
