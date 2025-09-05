import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HeroIllustration extends StatelessWidget {
  const HeroIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      height: 256,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          'https://storage.googleapis.com/uxpilot-auth.appspot.com/57f4ae2637-310534f60557d77a7aa1.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback illustration if image fails to load
            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE0F2FE),
                    Color(0xFFB3E5FC),
                    Color(0xFF81D4FA),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.people_alt_outlined,
                  size: 80,
                  color: Color(0xFF2563EB),
                ),
              ),
            );
          },
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          duration: 800.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 1000.ms, delay: 300.ms);
  }
}
