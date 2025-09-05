import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SignInButtons extends StatelessWidget {
  const SignInButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Sign In Button
        _buildSignInButton(
          icon: FontAwesomeIcons.google,
          label: 'Continue with Google',
          onTap: () {
            // TODO: Implement Google sign in
          },
          delay: 600,
        ),
        const SizedBox(height: 12),
        
        // Email Sign In Button
        _buildSignInButton(
          icon: FontAwesomeIcons.envelope,
          label: 'Continue with Email',
          onTap: () {
            // TODO: Implement email sign in
          },
          delay: 800,
        ),
      ],
    );
  }

  Widget _buildSignInButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: icon == FontAwesomeIcons.google 
                  ? const Color(0xFFEF4444) // red-500
                  : const Color(0xFF2563EB), // blue-600
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151), // gray-700
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideX(
          begin: 0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 800.ms, delay: delay.ms)
        .shimmer(
          duration: 2000.ms,
          delay: (delay + 400).ms,
          color: Colors.white.withValues(alpha: 0.3),
        );
  }
}
