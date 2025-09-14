import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            onPressed: () {
              // TODO: Open PDF file
            },
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
            onPressed: () {
              // TODO: Open DOCX file
            },
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
            onPressed: () {
              // TODO: Open Excel file
            },
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
          onPressed: () {
            // TODO: Open native share dialog
          },
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


