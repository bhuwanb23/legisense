import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back to Legisense',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          )
              .animate()
              .slideX(
                begin: -0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 800.ms),
          
          const SizedBox(height: 8),
          
          Text(
            "Let's simplify your documents",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          )
              .animate()
              .slideX(
                begin: -0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 800.ms, delay: 200.ms),
        ],
      ),
    );
  }
}
