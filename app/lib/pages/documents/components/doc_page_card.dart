import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DocPageCard extends StatefulWidget {
  const DocPageCard({super.key, required this.title, required this.paragraphs, this.sections});

  final String title;
  final List<String> paragraphs;
  final List<Widget>? sections; // optional extra sections like lists

  @override
  State<DocPageCard> createState() => _DocPageCardState();
}

class _DocPageCardState extends State<DocPageCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
              ),
              const SizedBox(height: 12),
              ...widget.paragraphs.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      p,
                      style: GoogleFonts.inter(fontSize: 14, height: 1.7, color: const Color(0xFF374151)),
                    ),
                  )),
              if (widget.sections != null) ...widget.sections!,
            ],
          ),
        ),
      ),
    );
  }
}


