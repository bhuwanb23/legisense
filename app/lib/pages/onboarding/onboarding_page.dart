import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';

/// Editorial letter hero — brand + one headline + CTA.
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
    final size = MediaQuery.sizeOf(context);
    final mark = (size.shortestSide * 0.28).clamp(96.0, 132.0);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Legisense',
                        style: GoogleFonts.spectral(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      const Spacer(flex: 2),
                      Center(
                        child: Image.asset(
                          'assets/images/legisense_mark.png',
                          width: mark,
                          height: mark,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const Spacer(flex: 2),
                      Text(
                        'Law made clear before you sign',
                        style: GoogleFonts.spectral(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: -0.5,
                          color: AppColors.ink,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Understand contracts without the jargon — India-first counsel in plain language.',
                        style: GoogleFonts.epilogue(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const Spacer(),
                      AuthPrimaryButton(
                        label: 'Get Started',
                        onPressed: () => _getStarted(context),
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.epilogue(
                              fontSize: 14,
                              color: AppColors.inkSoft,
                            ),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
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
                                  child: Text(
                                    'Sign in',
                                    style: GoogleFonts.epilogue(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
