import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_social_button.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';

/// Minimal welcome — inspiration landing rhythm.
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
    final mark = (size.shortestSide * 0.36).clamp(120.0, 168.0);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.7),
            radius: 1.1,
            colors: [
              Color(0xFFD7E9FA),
              AppColors.skyMist,
              Color(0xFFFBFCFE),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Legisense',
                          style: GoogleFonts.epilogue(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                            letterSpacing: -0.3,
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
                        Text.rich(
                          TextSpan(
                            style: GoogleFonts.epilogue(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              letterSpacing: -0.9,
                              color: AppColors.primaryNavy,
                            ),
                            children: const [
                              TextSpan(text: 'Law made\n'),
                              TextSpan(
                                text: 'clear',
                                style: TextStyle(color: AppColors.accentSky),
                              ),
                              TextSpan(text: ' before\nyou sign'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Join and understand contracts without the jargon.',
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
                        const SizedBox(height: 18),
                        AuthSocialRow(
                          onGoogle: () => showAuthComingSoon(context, 'Google'),
                          onFacebook: () => showAuthComingSoon(context, 'Facebook'),
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
                                const TextSpan(
                                  text: 'Already have an account? ',
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: GestureDetector(
                                    onTap: () {
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
                                        color: AppColors.primaryNavy,
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
      ),
    );
  }
}
