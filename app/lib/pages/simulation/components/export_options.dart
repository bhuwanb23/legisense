import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../theme/app_theme.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';
import 'styles.dart';

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

  @override
  Widget build(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n['export.title'] ?? 'Export Options',
          style: AppTheme.heading3.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _ExportButton(
              icon: Icons.picture_as_pdf,
              label: i18n['export.pdf'] ?? 'PDF Report',
              color: const Color(0xFFDC2626),
              onPressed: onExportPdf ?? () => _exportPdf(context),
            ),
            _ExportButton(
              icon: Icons.description,
              label: i18n['export.docx'] ?? 'DOCX Document',
              color: const Color(0xFF2563EB),
              onPressed: onExportDocx ?? () => _exportDocx(context),
            ),
            _ExportButton(
              icon: Icons.link,
              label: i18n['export.share'] ?? 'Share Link',
              color: const Color(0xFF059669),
              onPressed: onShare ?? () => _shareResults(context),
            ),
            _ExportButton(
              icon: Icons.table_chart,
              label: i18n['export.excel'] ?? 'Excel Data',
              color: const Color(0xFF16A34A),
              onPressed: () => _exportExcel(context),
            ),
          ],
        ),
      ],
    );
  }

  void _exportPdf(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
    _showExportDialog(context, 'PDF', i18n['export.generating.pdf'] ?? 'Generating PDF report...', () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((i18n['export.snack.pdf'] ?? 'PDF report exported: {name}.pdf').replaceFirst('{name}', documentTitle)),
          backgroundColor: const Color(0xFFDC2626),
          action: SnackBarAction(
            label: i18n['action.open'] ?? 'Open',
            textColor: Colors.white,
            onPressed: () => _openFile('$documentTitle.pdf'),
          ),
        ),
      );
    });
  }

  void _exportDocx(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
    _showExportDialog(context, 'DOCX', i18n['export.generating.docx'] ?? 'Generating Word document...', () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((i18n['export.snack.docx'] ?? 'Word document exported: {name}.docx').replaceFirst('{name}', documentTitle)),
          backgroundColor: const Color(0xFF2563EB),
          action: SnackBarAction(
            label: i18n['action.open'] ?? 'Open',
            textColor: Colors.white,
            onPressed: () => _openFile('$documentTitle.docx'),
          ),
        ),
      );
    });
  }

  void _exportExcel(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
    _showExportDialog(context, 'Excel', i18n['export.generating.excel'] ?? 'Generating Excel spreadsheet...', () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((i18n['export.snack.excel'] ?? 'Excel file exported: {name}.xlsx').replaceFirst('{name}', documentTitle)),
          backgroundColor: const Color(0xFF16A34A),
          action: SnackBarAction(
            label: i18n['action.open'] ?? 'Open',
            textColor: Colors.white,
            onPressed: () => _openFile('$documentTitle.xlsx'),
          ),
        ),
      );
    });
  }

  void _shareResults(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
    final shareText = 'Check out this simulation analysis for $documentTitle';
    Clipboard.setData(ClipboardData(text: shareText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(i18n['share.copied'] ?? 'Share link copied to clipboard'),
        backgroundColor: const Color(0xFF059669),
        action: SnackBarAction(
          label: i18n['action.share'] ?? 'Share',
          textColor: Colors.white,
          onPressed: () => _openShareDialog(context),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, String format, String message, VoidCallback onComplete) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
    
    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close dialog
        onComplete();
      }
    });
  }

  /// Opens a file using the system's default application
  Future<void> _openFile(String fileName) async {
    try {
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      
      // Check if file exists
      final file = File(filePath);
      if (await file.exists()) {
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          // Handle error cases
          debugPrint('Error opening file: ${result.message}');
        }
      } else {
        // File doesn't exist, show a message or create a placeholder
        debugPrint('File not found: $filePath');
        // In a real app, you might want to show a dialog or create the file
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  /// Opens the native share dialog
  Future<void> _openShareDialog(BuildContext context) async {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
    final shareText = 'Check out this simulation analysis for $documentTitle';
    try {
      await Share.share(
        shareText,
        subject: 'Legisense Simulation Analysis',
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      // Fallback to clipboard if sharing fails
      Clipboard.setData(ClipboardData(text: shareText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(i18n['share.dialog.failed'] ?? 'Share dialog failed, text copied to clipboard'), backgroundColor: Colors.orange),
        );
      }
    }
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(SimStyles.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(SimStyles.radiusM),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


