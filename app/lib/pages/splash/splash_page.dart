import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../auth/login_page.dart';
import '../onboarding/onboarding_page.dart';
import '../shell/main_shell.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _redirectDelay = Duration(milliseconds: 2400);

  late final AnimationController _contentController;
  late final Animation<double> _fadeIn;
  Timer? _redirectTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
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
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, animation, __) => next,
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: size.width * 0.42,
                height: size.width * 0.42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.25,
                      child: Lottie.asset(
                        'assets/lottie/logo_splash.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Image.asset(
                      'assets/images/legisense_mark.png',
                      width: size.width * 0.22,
                      height: size.width * 0.22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Legisense',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI Legal Advisor',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: AppColors.mute,
                ),
              ),
              const Spacer(flex: 3),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
