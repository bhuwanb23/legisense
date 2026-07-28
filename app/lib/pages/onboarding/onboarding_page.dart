import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../auth/register_page.dart';

/// Lightweight onboarding gate before Register.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  Future<void> _continue(BuildContext context) async {
    await SessionPrefs.setOnboardingSeen();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.skyWash, AppColors.skyMist],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(
                      3,
                      (_) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.progressIdle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Welcome to\nLegisense',
                  style: GoogleFonts.epilogue(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.6,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Contracts explained clearly — risks flagged before you sign.',
                  style: GoogleFonts.epilogue(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: AppColors.inkSoft,
                  ),
                ),
                const Spacer(),
                AuthPrimaryButton(
                  label: 'Continue',
                  onPressed: () => _continue(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
