import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SignInButtons extends StatelessWidget {
  final VoidCallback? onEmailPressed;
  
  const SignInButtons({
    super.key,
    this.onEmailPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Sign In Button
        _buildSignInButton(
          icon: FontAwesomeIcons.google,
          label: 'Continue with Google',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Google sign-in coming soon'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          delay: 600,
        ),
        const SizedBox(height: 12),
        
        // Email Sign In Button
        _buildSignInButton(
          icon: FontAwesomeIcons.envelope,
          label: 'Continue with Email',
          onTap: onEmailPressed ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email sign-in coming soon'),
                duration: Duration(seconds: 2),
              ),
            );
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
        .fadeIn(duration: 800.ms, delay: delay.ms);
  }
}
