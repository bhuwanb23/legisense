import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../auth/login_page.dart';
import '../onboarding/onboarding_page.dart';
import '../shell/main_shell.dart';

/// Splash — typographic brand on paper; quieter Lottie.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  static const _redirectDelay = Duration(milliseconds: 2600);

  late final AnimationController _contentController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  Timer? _redirectTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
      ),
    );

    _contentController.forward();
    _scheduleRedirect();
  }

  Future<void> _scheduleRedirect() async {
    final destination = await SessionPrefs.resolveSplashDestination();
    if (!mounted) return;

    _redirectTimer = Timer(_redirectDelay, () {
      if (!mounted || _navigated) return;
      _navigated = true;
      final Widget next = switch (destination) {
        SplashDestination.home => const MainShell(),
        SplashDestination.login => const LoginPage(),
        SplashDestination.onboarding => const OnboardingPage(),
      };
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 520),
          pageBuilder: (_, animation, __) => next,
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 55,
              child: Center(
                child: SizedBox(
                  width: size.width * 0.55,
                  height: size.width * 0.55,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0.35,
                        child: Lottie.asset(
                          'assets/lottie/logo_splash.json',
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                      FadeTransition(
                        opacity: _fadeIn,
                        child: Image.asset(
                          'assets/images/legisense_mark.png',
                          width: size.width * 0.28,
                          height: size.width * 0.28,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 45,
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Text(
                          'Legisense',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spectral(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            letterSpacing: -0.6,
                            color: AppColors.ink,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Your AI Legal Advisor',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.epilogue(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.accentGold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
