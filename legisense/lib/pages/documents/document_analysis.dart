import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../profile/language/language_scope.dart';
import 'language/strings.dart';

/// Analysis panel shell — no live LLM analysis until the new backend is ready.
class DocumentAnalysisPanel extends StatelessWidget {
  const DocumentAnalysisPanel({super.key, this.docId});

  final String? docId;

  @override
  Widget build(BuildContext context) {
    final i18n = DocumentsI18n.mapFor(
      LanguageScope.maybeOf(context)?.language ?? AppLanguage.en,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: AppTheme.textSecondary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              i18n['docs.analysis.empty'] ?? 'Analysis not available',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              i18n['docs.analysis.emptyHint'] ??
                  'AI contract analysis will return when the Node API is connected.',
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

/// Back-compat alias used by older imports.
typedef DocumentAnalysis = DocumentAnalysisPanel;
