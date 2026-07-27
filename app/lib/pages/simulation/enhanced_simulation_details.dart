import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../profile/language/language_scope.dart';
import 'language/strings.dart';

/// Simulation details shell — no live simulation until the new API is ready.
class EnhancedSimulationDetailsPage extends StatelessWidget {
  final String documentId;
  final String documentTitle;
  final Map<String, dynamic>? simulationData;

  const EnhancedSimulationDetailsPage({
    super.key,
    required this.documentId,
    required this.documentTitle,
    this.simulationData,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = SimulationI18n.mapFor(
      LanguageScope.maybeOf(context)?.language ?? AppLanguage.en,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(documentTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.chartLine,
                size: 40,
                color: AppTheme.textSecondary.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 16),
              Text(
                i18n['sim.detail.empty'] ?? 'Simulation unavailable',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                i18n['sim.detail.emptyHint'] ??
                    'What-if results for "$documentTitle" will appear once the Node API is connected.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
