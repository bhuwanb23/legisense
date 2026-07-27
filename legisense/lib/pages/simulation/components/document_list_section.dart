import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

/// Simulation document picker shell — empty until backend is ready.
class DocumentListSection extends StatelessWidget {
  final Function(String documentId, String documentTitle)? onDocumentTap;
  final Function(String documentId, String documentTitle)? onSimulate;

  const DocumentListSection({
    super.key,
    this.onDocumentTap,
    this.onSimulate,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = SimulationI18n.mapFor(
      LanguageScope.maybeOf(context)?.language ?? AppLanguage.en,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.flask,
              size: 40,
              color: AppTheme.textSecondary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              i18n['sim.empty.title'] ?? 'No simulations yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              i18n['sim.empty.subtitle'] ??
                  'What-if simulations will appear here after documents are connected to the new API.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
