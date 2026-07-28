import 'package:flutter/material.dart';

import '../../data/analysis_mock.dart';
import '../../data/dashboard_mock.dart';
import 'analysis_results_page.dart';

/// Compatibility entry from Home / Processing → master results.
class AnalysisStubPage extends StatelessWidget {
  const AnalysisStubPage({super.key, required this.document});

  final MockDocument document;

  @override
  Widget build(BuildContext context) {
    return AnalysisResultsPage(
      result: AnalysisResult.fromMockDocument(document),
    );
  }
}
