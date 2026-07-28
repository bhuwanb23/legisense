import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../auth/login_page.dart';
import '../onboarding/onboarding_page.dart';
import '../shell/main_shell.dart';

/// Page 1 — Splash Screen
///
/// THESIS: Soft sky-blue studio; brand mark leads; no CTA — time routes the user.
/// OWN-WORLD: sky wash, navy ink, Lottie + mark, Epilogue/Spectral system.
/// STORY: Trust + clarity in one breath → onboarding or home.
/// FIRST VIEWPORT: centered logo field, wordmark, tagline; ambient blobs only.
/// FORM: Dribbble soft-blue splash grammar, legal calm.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const _redirectDelay = Duration(milliseconds: 2600);

  late final AnimationController _contentController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final AnimationController _blobController;

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
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
      ),
    );

    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);

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
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.skyWash, AppColors.skyMist, Color(0xFFEEF5FC)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _blobController,
                builder: (context, _) {
                  final t = _blobController.value;
                  return Stack(
                    children: [
                      Positioned(
                        top: size.height * (0.08 + t * 0.02),
                        left: -size.width * 0.18,
                        child: _AmbientBlob(
                          diameter: size.width * 0.62,
                          color: AppColors.accentSoft.withValues(alpha: 0.45),
                        ),
                      ),
                      Positioned(
                        top: size.height * (0.22 - t * 0.015),
                        right: -size.width * 0.2,
                        child: _AmbientBlob(
                          diameter: size.width * 0.55,
                          color: AppColors.accentSky.withValues(alpha: 0.22),
                        ),
                      ),
                      Positioned(
                        bottom: size.height * 0.12,
                        left: size.width * 0.2,
                        child: _AmbientBlob(
                          diameter: size.width * 0.4,
                          color: AppColors.accentSoft.withValues(alpha: 0.28),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Column(
                children: [
                  Expanded(
                    flex: 58,
                    child: Center(
                      child: SizedBox(
                        width: size.width * 0.72,
                        height: size.width * 0.72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Lottie.asset(
                              'assets/lottie/logo_splash.json',
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                            FadeTransition(
                              opacity: _fadeIn,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.86, end: 1).animate(
                                  CurvedAnimation(
                                    parent: _contentController,
                                    curve: const Interval(
                                      0.1,
                                      0.85,
                                      curve: Curves.easeOutBack,
                                    ),
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/images/legisense_mark.png',
                                  width: size.width * 0.34,
                                  height: size.width * 0.34,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 42,
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Legisense',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.epilogue(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  letterSpacing: -0.8,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Your AI Legal Advisor',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.epilogue(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const Spacer(),
                              const _LoadingPulse(),
                              const SizedBox(height: AppSpacing.xxl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientBlob extends StatelessWidget {
  const _AmbientBlob({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _LoadingPulse extends StatefulWidget {
  const _LoadingPulse();

  @override
  State<_LoadingPulse> createState() => _LoadingPulseState();
}

class _LoadingPulseState extends State<_LoadingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 36,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.primaryNavy,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
    );
  }
}
