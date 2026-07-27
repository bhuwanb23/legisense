import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeText extends StatelessWidget {
  const WelcomeText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome to Legal Clarity',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        )
            .animate()
            .slideY(
              begin: 0.3,
              duration: 600.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(duration: 800.ms, delay: 500.ms),
        
        const SizedBox(height: 8),
        
        Text(
          'Navigate complex legal documents with confidence.\nGet instant insights and plain-English explanations.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFDBEAFE), // blue-100
            height: 1.6,
            letterSpacing: 0.1,
          ),
        )
            .animate()
            .slideY(
              begin: 0.3,
              duration: 600.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(duration: 800.ms, delay: 700.ms),
      ],
    );
  }
}
