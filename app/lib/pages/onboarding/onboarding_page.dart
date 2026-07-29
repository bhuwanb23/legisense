import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  Future<void> _getStarted(BuildContext context) async {
    await SessionPrefs.setOnboardingSeen();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mark = (MediaQuery.sizeOf(context).shortestSide * 0.28).clamp(96.0, 128.0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Legisense',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(flex: 2),
              Center(
                child: Image.asset(
                  'assets/images/legisense_mark.png',
                  width: mark,
                  height: mark,
                ),
              ),
              const Spacer(flex: 2),
              Text(
                'Law made clear before you sign',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Understand contracts without the jargon — India-first counsel in plain language.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  height: 1.45,
                  color: AppColors.mute,
                ),
              ),
              const Spacer(),
              AuthPrimaryButton(
                label: 'Get Started',
                showArrow: true,
                onPressed: () => _getStarted(context),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    await SessionPrefs.setOnboardingSeen();
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginPage(),
                      ),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.mute,
                      ),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign in',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
