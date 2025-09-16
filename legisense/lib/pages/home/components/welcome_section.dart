import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LanguageScope.maybeOf(context);
    final i18n = HomeI18n.mapFor(controller?.language ?? AppLanguage.en);
    final greeting = _getGreeting(i18n);
    final motivationalMessage = _getMotivationalMessage(i18n);
    
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

  String _getGreeting(Map<String, String> i18n) {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return i18n['welcome.morning'] ?? 'Good morning! Welcome to Legisense';
    } else if (hour < 17) {
      return i18n['welcome.afternoon'] ?? 'Good afternoon! Welcome to Legisense';
    } else {
      return i18n['welcome.evening'] ?? 'Good evening! Welcome to Legisense';
    }
  }

  String _getMotivationalMessage(Map<String, String> i18n) {
    final messages = [
      i18n['welcome.msg1'] ?? "Let's simplify your documents and make legal analysis effortless",
      i18n['welcome.msg2'] ?? 'Transform complex contracts into clear insights',
      i18n['welcome.msg3'] ?? 'Your intelligent legal companion is ready to help',
      i18n['welcome.msg4'] ?? 'Discover hidden clauses and potential risks in your documents',
      i18n['welcome.msg5'] ?? 'Make informed decisions with AI-powered document analysis',
      i18n['welcome.msg6'] ?? 'Turn legal complexity into simple understanding',
    ];
    
    // Use day of year to cycle through messages consistently
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return messages[dayOfYear % messages.length];
  }
}
