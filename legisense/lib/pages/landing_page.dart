import 'dart:math' as math;

import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Words to rotate in the headline
  final List<String> _keywords = const [
    'AI-Powered',
    'Fast',
    'Secure',
    'Beautiful',
  ];
  int _keywordIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Rotate the keyword every 2 seconds
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      while (mounted) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (!mounted) break;
        setState(() {
          _keywordIndex = (_keywordIndex + 1) % _keywords.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _AnimatedGradientBackground(progress: _controller.value),
              // Floating decorative blobs
              ..._buildFloatingBlobs(context, _controller.value),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: isWide
                              ? Row(
                                  children: [
                                    Expanded(child: _buildHeroText(theme)),
                                    const SizedBox(width: 32),
                                    Expanded(child: _buildShowcaseCard(theme)),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildShowcaseCard(theme),
                                    const SizedBox(height: 32),
                                    _buildHeroText(theme),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildFloatingBlobs(BuildContext context, double t) {
    final size = MediaQuery.of(context).size;
    final blobs = <_BlobSpec>[
      _BlobSpec(offset: const Offset(0.15, 0.25), baseSize: 180, hue: 260),
      _BlobSpec(offset: const Offset(0.85, 0.20), baseSize: 140, hue: 320),
      _BlobSpec(offset: const Offset(0.20, 0.80), baseSize: 120, hue: 200),
      _BlobSpec(offset: const Offset(0.80, 0.75), baseSize: 160, hue: 160),
    ];

    return blobs.map((blob) {
      final wobble = math.sin((t * 2 * math.pi) + blob.hue) * 8;
      final x = blob.offset.dx * size.width + wobble;
      final y = blob.offset.dy * size.height + wobble;
      final s = blob.baseSize + math.cos((t * 2 * math.pi) - blob.hue) * 12;
      return Positioned(
        left: x - s / 2,
        top: y - s / 2,
        child: _SoftBlob(
          size: s,
          color: HSVColor.fromAHSV(0.18, blob.hue.toDouble(), 0.75, 1.0).toColor(),
        ),
      );
    }).toList();
  }

  Widget _buildHeroText(ThemeData theme) {
    final headline = theme.textTheme.displaySmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      height: 1.1,
    );
    final sub = theme.textTheme.titleMedium?.copyWith(
      color: Colors.white70,
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, size: 18, color: Colors.white70),
              SizedBox(width: 8),
              Text('Welcome to Legisense', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Text('An ', style: headline),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
                    .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(
                _keywords[_keywordIndex],
                key: ValueKey(_keywordIndex),
                style: headline?.copyWith(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFF9D6BFF), Color(0xFF00D4FF)],
                    ).createShader(const Rect.fromLTWH(0, 0, 300, 60)),
                ),
              ),
            ),
            Text(' experience for legal insights', style: headline),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Discover laws, precedents, and smart analysis with delightful, animated UI.',
          style: sub,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _ShinyButton(
              onPressed: () {},
              label: 'Get Started',
              icon: Icons.rocket_launch,
              primary: true,
            ),
            const SizedBox(width: 12),
            _ShinyButton(
              onPressed: () {},
              label: 'Learn More',
              icon: Icons.play_circle_fill,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShowcaseCard(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative grid
            CustomPaint(
              painter: _GridPainter(opacity: 0.15),
              size: const Size(double.infinity, 320),
            ),
            SizedBox(
              height: 320,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _IndicatorDot(color: const Color(0xFF5CE0FF)),
                        const SizedBox(width: 8),
                        _IndicatorDot(color: const Color(0xFFB39DFF)),
                        const SizedBox(width: 8),
                        _IndicatorDot(color: const Color(0xFFFF9DD6)),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Interactive Visuals',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Smooth animations, glowing shapes, and a crisp glass UI.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (math.sin(_controller.value * 2 * math.pi) + 1) / 2,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      color: const Color(0xFF8E7CFF),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.security, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Privacy-first, locally processed', style: TextStyle(color: Colors.white70)),
                      ],
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

class _AnimatedGradientBackground extends StatelessWidget {
  const _AnimatedGradientBackground({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorsA = [
      const Color(0xFF0E1B4D),
      const Color(0xFF1E2A78),
      const Color(0xFF4C3C9E),
    ];
    final colorsB = [
      const Color(0xFF0E2A4D),
      const Color(0xFF183B6B),
      const Color(0xFF2B5EA6),
    ];

    Color lerp(Color a, Color b) => Color.lerp(a, b, 0.5 + 0.5 * math.sin(progress * 2 * math.pi))!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lerp(colorsA[0], colorsB[0]),
            lerp(colorsA[1], colorsB[1]),
            lerp(colorsA[2], colorsB[2]),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _RingsPainter(progress: progress, opacity: 0.12),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.8), blurRadius: size * 0.6, spreadRadius: size * 0.2),
        ],
      ),
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 1;

    const step = 22.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.opacity != opacity;
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.progress, this.opacity = 0.1});

  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.4);
    final baseColor = Colors.white.withOpacity(opacity);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = baseColor;

    for (int i = 0; i < 6; i++) {
      final radius = i * 80 + 80 + math.sin(progress * 2 * math.pi + i) * 10;
      canvas.drawCircle(center, radius.toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}

class _ShinyButton extends StatefulWidget {
  const _ShinyButton({required this.onPressed, required this.label, this.icon, this.primary = false});

  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final bool primary;

  @override
  State<_ShinyButton> createState() => _ShinyButtonState();
}

class _ShinyButtonState extends State<_ShinyButton> with SingleTickerProviderStateMixin {
  late final AnimationController _shineCtrl;

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.primary ? const Color(0xFF805BFF) : Colors.white.withOpacity(0.08);
    final fg = widget.primary ? Colors.white : Colors.white;
    final border = widget.primary ? Colors.white.withOpacity(0.0) : Colors.white.withOpacity(0.18);

    return AnimatedBuilder(
      animation: _shineCtrl,
      builder: (context, _) {
        return InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
              color: bg,
              boxShadow: widget.primary
                  ? [
                      const BoxShadow(color: Color(0x66805BFF), blurRadius: 18, offset: Offset(0, 8)),
                    ]
                  : null,
              gradient: widget.primary
                  ? LinearGradient(
                      colors: const [Color(0xFF805BFF), Color(0xFF5E8BFF)],
                      transform: GradientRotation(_shineCtrl.value * 2 * math.pi),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(widget.label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BlobSpec {
  const _BlobSpec({required this.offset, required this.baseSize, required this.hue});

  final Offset offset; // as fraction of screen size
  final double baseSize;
  final int hue;
}


