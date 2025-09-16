import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../theme/app_theme.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Options',
          style: AppTheme.heading3.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _ExportButton(
              icon: Icons.picture_as_pdf,
              label: 'PDF Report',
              color: const Color(0xFFDC2626),
              onPressed: onExportPdf ?? () => _exportPdf(context),
            ),
            _ExportButton(
              icon: Icons.description,
              label: 'DOCX Document',
              color: const Color(0xFF2563EB),
              onPressed: onExportDocx ?? () => _exportDocx(context),
            ),
            _ExportButton(
              icon: Icons.link,
              label: 'Share Link',
              color: const Color(0xFF059669),
              onPressed: onShare ?? () => _shareResults(context),
            ),
            _ExportButton(
              icon: Icons.table_chart,
              label: 'Excel Data',
              color: const Color(0xFF16A34A),
              onPressed: () => _exportExcel(context),
            ),
          ],
        ),
      ],
    );
  }

  void _exportPdf(BuildContext context) {
    _showExportDialog(context, 'PDF', 'Generating PDF report...', () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF report exported: $documentTitle.pdf'),
          backgroundColor: const Color(0xFFDC2626),
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => _openFile('$documentTitle.pdf'),
          ),
        ),
      );
    });
  }

  void _exportDocx(BuildContext context) {
    _showExportDialog(context, 'DOCX', 'Generating Word document...', () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Word document exported: $documentTitle.docx'),
          backgroundColor: const Color(0xFF2563EB),
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => _openFile('$documentTitle.docx'),
          ),
        ),
      );
    });
  }

  void _exportExcel(BuildContext context) {
    _showExportDialog(context, 'Excel', 'Generating Excel spreadsheet...', () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel file exported: $documentTitle.xlsx'),
          backgroundColor: const Color(0xFF16A34A),
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => _openFile('$documentTitle.xlsx'),
          ),
        ),
      );
    });
  }

  void _shareResults(BuildContext context) {
    final shareText = 'Check out this simulation analysis for $documentTitle';
    Clipboard.setData(ClipboardData(text: shareText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share link copied to clipboard'),
        backgroundColor: const Color(0xFF059669),
        action: SnackBarAction(
          label: 'Share',
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
          const SnackBar(
            content: Text('Share dialog failed, text copied to clipboard'),
            backgroundColor: Colors.orange,
          ),
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
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


