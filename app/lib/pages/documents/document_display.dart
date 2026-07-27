import 'package:flutter/material.dart';
import '../documents/data/sample_documents.dart';
import '../../theme/app_theme.dart';

/// Document display shell — retained for layout compatibility.
class DocumentDisplayPanel extends StatelessWidget {
  const DocumentDisplayPanel({super.key, this.document});

  final SampleDocument? document;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          document == null
              ? 'Document viewer will reconnect with the new backend.'
              : document!.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Back-compat alias.
typedef DocumentDisplay = DocumentDisplayPanel;
