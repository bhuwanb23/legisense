import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../main.dart';

class SuggestedQuestions extends StatelessWidget {
  const SuggestedQuestions({super.key, required this.questions});
  final List<String> questions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: questions.map((q) => _QuestionChip(text: q)).toList(),
    );
  }
}

class _QuestionChip extends StatefulWidget {
  const _QuestionChip({required this.text});
  final String text;

  @override
  State<_QuestionChip> createState() => _QuestionChipState();
}

class _QuestionChipState extends State<_QuestionChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: _hover ? 1.03 : 1.0,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            // Navigate to chat/companion - for now, switch to Simulation tab or keep placeholder
            navigateToPage(2);
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFF475569)),
                const SizedBox(width: 6),
                Text(widget.text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


