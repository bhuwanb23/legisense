import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/dashboard_mock.dart';
import '../../theme/app_theme.dart';

/// Placeholder analysis results for a recent mock document.
class AnalysisStubPage extends StatelessWidget {
  const AnalysisStubPage({super.key, required this.document});

  final MockDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyMist,
      appBar: AppBar(
        backgroundColor: AppColors.skyMist,
        elevation: 0,
        foregroundColor: AppColors.primaryNavy,
        title: Text(
          'Analysis',
          style: GoogleFonts.epilogue(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              document.title,
              style: GoogleFonts.epilogue(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${document.typeLabel} · ${document.relativeDate}',
              style: GoogleFonts.epilogue(
                fontSize: 14,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cloud,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                'Full risk breakdown and clause highlights will appear here once analysis is wired to the backend.',
                style: GoogleFonts.epilogue(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
