import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Shared paper chrome for tab pages.
class StubScaffold extends StatelessWidget {
  const StubScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    this.child,
  });

  final String title;
  final String subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: GoogleFonts.spectral(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.ink,
                  fontStyle: FontStyle.normal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.epilogue(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.inkSoft,
                ),
              ),
              if (child != null) ...[
                const SizedBox(height: 24),
                Expanded(child: child!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
