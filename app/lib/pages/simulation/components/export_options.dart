import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

/// Export UI shell — file export returns with the new backend.
class ExportOptions extends StatelessWidget {
  const ExportOptions({
    super.key,
    this.onExportPdf,
    this.onExportDocx,
    this.onShare,
    this.documentTitle = 'Simulation Report',
  });

  final VoidCallback? onExportPdf;
  final VoidCallback? onExportDocx;
  final VoidCallback? onShare;
  final String documentTitle;

  void _comingSoon(BuildContext context) {
    final i18n = SimulationI18n.mapFor(
      LanguageScope.maybeOf(context)?.language ?? AppLanguage.en,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          i18n['sim.export.comingSoon'] ??
              'Export will be available when the new backend is connected.',
        ),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = SimulationI18n.mapFor(
      LanguageScope.maybeOf(context)?.language ?? AppLanguage.en,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          i18n['sim.export.title'] ?? 'Export',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onExportPdf ?? () => _comingSoon(context),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(i18n['sim.export.pdf'] ?? 'PDF'),
            ),
            OutlinedButton.icon(
              onPressed: onExportDocx ?? () => _comingSoon(context),
              icon: const Icon(Icons.description_outlined),
              label: Text(i18n['sim.export.docx'] ?? 'DOCX'),
            ),
            OutlinedButton.icon(
              onPressed: onShare ?? () => _comingSoon(context),
              icon: const Icon(Icons.share_outlined),
              label: Text(i18n['sim.export.share'] ?? 'Share'),
            ),
          ],
        ),
      ],
    );
  }
}
