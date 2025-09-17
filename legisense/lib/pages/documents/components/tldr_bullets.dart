import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

class TldrBullets extends StatelessWidget {
  const TldrBullets({super.key, required this.bullets});

  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1D4ED8),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.summarize, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                DocumentsI18n.mapFor(LanguageScope.of(context).language)['analysis.tldr.title'] ?? 'TL;DR Summary',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(bullets.length.clamp(0, 5), (index) {
            final text = bullets[index];
            final delay = (index + 1) * 60;
            return _AnimatedBullet(
              text: text,
              color: theme.colorScheme.primary,
              delayMs: delay,
            );
          }),
        ],
      ),
    );
  }
}

class _AnimatedBullet extends StatefulWidget {
  const _AnimatedBullet({required this.text, required this.color, required this.delayMs});
  final String text;
  final Color color;
  final int delayMs;

  @override
  State<_AnimatedBullet> createState() => _AnimatedBulletState();
}

class _AnimatedBulletState extends State<_AnimatedBullet> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(_fade);
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 7, right: 10),
                decoration: BoxDecoration(color: const Color(0xFF1D4ED8), borderRadius: BorderRadius.circular(4)),
              ),
              Expanded(
                child: Text(
                  widget.text,
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A), height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


