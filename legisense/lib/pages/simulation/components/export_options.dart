import 'package:flutter/material.dart';

class ExportOptions extends StatelessWidget {
  const ExportOptions({super.key, this.onExportPdf, this.onExportDocx, this.onShare});
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportDocx;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: [
        ElevatedButton.icon(onPressed: onExportPdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF')),
        ElevatedButton.icon(onPressed: onExportDocx, icon: const Icon(Icons.description), label: const Text('DOCX')),
        ElevatedButton.icon(onPressed: onShare, icon: const Icon(Icons.link), label: const Text('Share')),
      ],
    );
  }
}


