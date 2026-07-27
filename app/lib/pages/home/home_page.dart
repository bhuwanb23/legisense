import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Placeholder home — features reconnect with the new backend.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.skyMist, AppColors.skyWash],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Home',
                    style: GoogleFonts.epilogue(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your workspace will live here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.epilogue(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
