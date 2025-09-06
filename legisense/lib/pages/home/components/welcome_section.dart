import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back to Legisense',
            style: AppTheme.heading2,
          )
              .animate()
              .slideX(
                begin: -0.3,
                duration: AppTheme.animationMedium,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: AppTheme.animationSlow),
          
          const SizedBox(height: AppTheme.spacingS),
          
          Text(
            "Let's simplify your documents",
            style: AppTheme.subtitle,
          )
              .animate()
              .slideX(
                begin: -0.3,
                duration: AppTheme.animationMedium,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),
        ],
      ),
    );
  }
}
