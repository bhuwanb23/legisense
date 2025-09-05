import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LogoSection extends StatelessWidget {
  const LogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo with scale balanced icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            FontAwesomeIcons.scaleBalanced,
            size: 32,
            color: Color(0xFF2563EB), // blue-600
          ),
        )
            .animate()
            .scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 800.ms),
        
        const SizedBox(height: 16),
        
        // App Name
        Text(
          'Legisense',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        )
            .animate()
            .slideY(
              begin: 0.3,
              duration: 600.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(duration: 800.ms, delay: 200.ms),
        
        const SizedBox(height: 8),
        
        // Tagline
        Text(
          '"Law, made human."',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFDBEAFE), // blue-100
            letterSpacing: 0.2,
          ),
        )
            .animate()
            .slideY(
              begin: 0.3,
              duration: 600.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(duration: 800.ms, delay: 400.ms),
      ],
    );
  }
}
