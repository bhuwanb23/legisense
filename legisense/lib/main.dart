import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'pages/login/login.dart';
import 'pages/home/home_page.dart';
import 'pages/documents/documents_page.dart';
import 'pages/simulation/simulation_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/profile/language/language_scope.dart';
import 'pages/ai_chat/chat_overlay.dart';

// Global navigation key to access the main app state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global reference to the AppWrapper state
_AppWrapperState? _appWrapperState;

void main() {
  runApp(const LegisenseApp());
}

final LanguageController appLanguageController = LanguageController(AppLanguage.en);

class LegisenseApp extends StatelessWidget {
  const LegisenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      controller: appLanguageController,
      child: MaterialApp(
        title: 'Legisense',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
          useMaterial3: true,
        ),
        home: const AppWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool isLoggedIn = false;
  int currentPageIndex = 0;
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    _appWrapperState = this;
    // Show animated intro briefly, then continue to the app
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _showIntro = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _appWrapperState = null;
    super.dispose();
  }

  void handleLoginSuccess() {
    setState(() {
      isLoggedIn = true;
    });
  }

  void handleLogout() {
    setState(() {
      isLoggedIn = false;
      currentPageIndex = 0;
    });
  }

  void onPageChanged(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return const AnimatedIntro();
    }

    if (!isLoggedIn) {
      return LoginPage(
        onLoginSuccess: handleLoginSuccess,
      );
    }

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            // Main content area with bottom padding to account for navbar
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: IndexedStack(
                  index: currentPageIndex,
                  children: [
                    const HomePage(),
                    const DocumentsPage(),
                    const SimulationPage(),
                    ProfilePage(onLogout: handleLogout),
                  ],
                ),
              ),
            ),
            // AI Chat overlay floating on top
            const ChatOverlay(),
            
            // Bottom navigation is provided per-page now
          ],
        ),
      ),
    );
  }
}

class AnimatedIntro extends StatefulWidget {
  const AnimatedIntro({super.key});

  @override
  State<AnimatedIntro> createState() => _AnimatedIntroState();
}

class _AnimatedIntroState extends State<AnimatedIntro>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Slate-900
              Color(0xFF1E3A8A), // Indigo-800
              Color(0xFF312E81), // Indigo-900
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated gradient blobs
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  final t = _bgController.value * 2 * 3.1415926535;
                  return CustomPaint(
                    painter: _BlobPainter(time: t),
                  );
                },
              ),
            ),
            // Subtle particle layer
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  final t = _bgController.value * 2 * 3.1415926535;
                  return CustomPaint(
                    painter: _ParticlesPainter(time: t),
                  );
                },
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(_scale),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rotating ring behind logo
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: AnimatedBuilder(
                        animation: _bgController,
                        builder: (context, _) {
                          final angle = _bgController.value * 2 * 3.1415926535;
                          return Transform.rotate(
                            angle: angle,
                            child: CustomPaint(
                              painter: _RingPainter(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                          );
                        },
                      ),
                    ),
                    // Logo (frosted glass card + gradient icon)
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 950),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, t, child) {
                        final bg = Colors.white.withValues(alpha: 0.10 + 0.06 * t);
                        final br = Colors.white.withValues(alpha: 0.25 + 0.10 * t);
                        return Transform.translate(
                          offset: Offset(0, (1 - t) * 16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withValues(alpha: 0.18 * t),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: br, width: 1),
                                  ),
                                  child: Center(
                                    child: ShaderMask(
                                      shaderCallback: (rect) => const LinearGradient(
                                        colors: [
                                          Color(0xFF93C5FD), // blue-300
                                          Color(0xFFA78BFA), // violet-300
                                          Color(0xFFFCA5A5), // rose-300
                                        ],
                                      ).createShader(rect),
                                      blendMode: BlendMode.srcIn,
                                      child: const Icon(
                                        Icons.gavel_rounded,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // App title with color alpha animation (no Opacity widget)
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, t, child) {
                        return _GradientText(
                          'Legisense',
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.95 * t),
                              const Color(0xFF93C5FD).withValues(alpha: 0.95 * t),
                              const Color(0xFFA78BFA).withValues(alpha: 0.95 * t),
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Subtitle with color alpha animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOut,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, t, child) {
                        return Text(
                          'AI-powered legal document insight',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9 * t.clamp(0.0, 1.0)),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double time;
  _BlobPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // Moving radial blobs
    void blob(Offset c, double r, List<Color> colors) {
      final rect = Rect.fromCircle(center: c, radius: r);
      paint.shader = RadialGradient(colors: colors).createShader(rect);
      canvas.drawCircle(c, r, paint);
    }

    final w = size.width;
    final h = size.height;
    final dx1 = (math.cos(time) * 0.15 + 0.35) * w;
    final dy1 = (math.sin(time * 1.2) * 0.10 + 0.3) * h;
    final dx2 = (math.cos(time * 0.8 + 1.6) * 0.18 + 0.7) * w;
    final dy2 = (math.sin(time * 1.05 + 0.8) * 0.12 + 0.6) * h;

    blob(Offset(dx1, dy1), w * 0.35, [
      const Color(0x66FFFFFF),
      Colors.transparent,
    ]);
    blob(Offset(dx2, dy2), w * 0.40, [
      const Color(0x33FFFFFF),
      Colors.transparent,
    ]);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) => oldDelegate.time != time;
}

class _RingPainter extends CustomPainter {
  final Color color;
  _RingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;

    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(28)), paint);

    // Small ticks
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * 2 * 3.1415926535;
      final cx = size.width / 2 + (size.width / 2 - 10) * math.cos(a);
      final cy = size.height / 2 + (size.height / 2 - 10) * math.sin(a);
      canvas.drawCircle(Offset(cx, cy), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.color != color;
}

// Global function to navigate to a specific page from anywhere in the app
void navigateToPage(int pageIndex) {
  // Try to change the page index first
  if (_appWrapperState != null) {
    _appWrapperState!.onPageChanged(pageIndex);
  } else {
    // Alternative approach: use the navigator key to access the context
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Find the AppWrapper in the widget tree
      final appWrapperState = context.findAncestorStateOfType<_AppWrapperState>();
      if (appWrapperState != null) {
        appWrapperState.onPageChanged(pageIndex);
      }
    }
  }
}

class _ParticlesPainter extends CustomPainter {
  final double time;
  _ParticlesPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;

    // Gently moving, twinkling particles
    const int particleCount = 60;
    for (int i = 0; i < particleCount; i++) {
      final seed = i * 0.47;
      final px = (math.sin(time * 0.6 + seed) * 0.45 + 0.5) * width;
      final py = (math.cos(time * 0.55 + seed * 1.3) * 0.45 + 0.5) * height;
      final base = (math.sin(time * 1.2 + seed * 2.0) * 0.5 + 0.5);
      final alpha = 0.06 + 0.12 * base;
      final radius = 0.6 + 1.8 * base;
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => oldDelegate.time != time;
}

class _GradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle style;

  const _GradientText(this.text, {required this.gradient, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(Offset.zero & bounds.size),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style),
    );
  }
}
