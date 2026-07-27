import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

/// Upload UI shell — no backend connection yet.
class UploadZone extends StatelessWidget {
  const UploadZone({super.key});

  void _onTap(BuildContext context) {
    final lang = LanguageScope.maybeOf(context)?.language ?? AppLanguage.en;
    final i18n = HomeI18n.mapFor(lang);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          i18n['upload.snackbar.comingSoon'] ??
              'Upload will reconnect when the new backend is ready.',
        ),
        backgroundColor: AppTheme.primaryBlue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = ResponsiveHelper.isSmallScreen(context);
    final lang = LanguageScope.maybeOf(context)?.language ?? AppLanguage.en;
    final i18n = HomeI18n.mapFor(lang);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsivePadding(
          context,
          small: AppTheme.spacingS,
          medium: AppTheme.spacingS + 6,
          large: AppTheme.spacingM,
        ),
        vertical: ResponsiveHelper.getResponsivePadding(
          context,
          small: AppTheme.spacingS,
          medium: AppTheme.spacingS + 6,
          large: AppTheme.spacingM,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(context),
          borderRadius: BorderRadius.circular(isSmall ? AppTheme.radiusM : AppTheme.radiusL),
          child: Container(
            padding: EdgeInsets.all(isSmall ? AppTheme.spacingS : AppTheme.spacingM - 2),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isSmall ? AppTheme.radiusM : AppTheme.radiusL),
              border: Border.all(color: AppTheme.secondaryBlueLight, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: isSmall ? 56 : 72,
                  height: isSmall ? 56 : 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FontAwesomeIcons.cloudArrowUp,
                    size: isSmall ? 22 : 28,
                    color: AppTheme.primaryBlue,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                SizedBox(height: isSmall ? 12 : 16),
                Text(
                  i18n['upload.title'] ?? 'Upload a contract',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  i18n['upload.subtitle'] ??
                      'PDF upload will be available once the new API is connected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 12 : 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Text(
                    i18n['upload.cta'] ?? 'Choose PDF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
