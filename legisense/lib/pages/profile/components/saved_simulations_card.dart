import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_theme.dart';
import '../language/language_scope.dart';
import '../language/strings.dart';

class SavedSimulationsCard extends StatelessWidget {
  final VoidCallback? onCreateSimulation;

  const SavedSimulationsCard({
    super.key,
    this.onCreateSimulation,
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
              i18n['savedSimulations.title'] ?? 'Saved Simulations',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Empty state content
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Folder icon
                  Icon(
                    FontAwesomeIcons.folderOpen,
                    size: 48,
                    color: AppTheme.borderLight,
                  ),
                  
                  const SizedBox(height: AppTheme.spacingM),
                  
                  // Empty state text
                  Text(
                    i18n['savedSimulations.empty'] ?? 'No saved simulations yet',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingS),
                  
                  // Create simulation button
                  GestureDetector(
                    onTap: onCreateSimulation,
                    child: Text(
                      i18n['savedSimulations.create'] ?? 'Create your first simulation',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
