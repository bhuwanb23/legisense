import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final motivationalMessage = _getMotivationalMessage();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS + 6),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: AppTheme.heading3,
          )
              .animate()
              .slideX(
                begin: -0.3,
                duration: AppTheme.animationMedium,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: AppTheme.animationSlow),
          
          const SizedBox(height: AppTheme.spacingS - 2),
          
          Text(
            motivationalMessage,
            style: AppTheme.bodySmall,
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good morning! Welcome to Legisense';
    } else if (hour < 17) {
      return 'Good afternoon! Welcome to Legisense';
    } else {
      return 'Good evening! Welcome to Legisense';
    }
  }

  String _getMotivationalMessage() {
    final messages = [
      "Let's simplify your documents and make legal analysis effortless",
      "Transform complex contracts into clear insights",
      "Your intelligent legal companion is ready to help",
      "Discover hidden clauses and potential risks in your documents",
      "Make informed decisions with AI-powered document analysis",
      "Turn legal complexity into simple understanding",
    ];
    
    // Use day of year to cycle through messages consistently
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return messages[dayOfYear % messages.length];
  }
}
