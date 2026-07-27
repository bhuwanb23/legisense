import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

/// Recent files shell — empty until the new backend is wired.
class RecentFiles extends StatelessWidget {
  const RecentFiles({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.maybeOf(context)?.language ?? AppLanguage.en;
    final i18n = HomeI18n.mapFor(lang);
    final isSmall = ResponsiveHelper.isSmallScreen(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsivePadding(
          context,
          small: AppTheme.spacingS,
          medium: AppTheme.spacingS + 6,
          large: AppTheme.spacingM,
        ),
      ),
      padding: EdgeInsets.all(isSmall ? AppTheme.spacingM : AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n['recent.title'] ?? 'Recent files',
            style: TextStyle(
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Icon(
                  FontAwesomeIcons.folderOpen,
                  size: 36,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  i18n['recent.empty'] ?? 'No documents yet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  i18n['recent.emptyHint'] ??
                      'Uploaded contracts will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}
