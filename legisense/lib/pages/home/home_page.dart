import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'components/components.dart';
import '../../components/main_header.dart';
import '../../theme/app_theme.dart';
import '../profile/language/language_scope.dart';
import 'language/strings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  static const double _fixedHeaderHeight = 96; // slightly smaller header offset

  Future<void> _onRefresh() async {
    // Trigger refresh of RecentFiles component
    // The RecentFiles component will handle its own refresh logic
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = HomeI18n.mapFor(scope?.language ?? AppLanguage.en);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // from-blue-50
              Color(0xFFEEF2FF), // via-indigo-50
              Color(0xFFFAF5FF), // to-purple-50
              Color(0xFFF0F9FF), // sky-50
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Enhanced background floating icons
            const BackgroundIcons(),
            
            // Animated background elements
            _buildAnimatedBackground(),
            
            // Main content with pull-to-refresh (offset below header)
            SafeArea(
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _onRefresh,
                color: AppTheme.primaryBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: _fixedHeaderHeight + 8),
                      
                      // Welcome Section with staggered animation
                      const WelcomeSection()
                          .animate()
                          .slideX(
                            begin: -0.3,
                            duration: AppTheme.animationSlow,
                            curve: Curves.easeOut,
                          )
                          ,
                      
                      // Upload Zone with enhanced animation
                      const UploadZone()
                          .animate()
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            duration: AppTheme.animationSlow,
                            curve: Curves.elasticOut,
                          )
                          ,
                      
                      // Recent Files with slide animation
                      const RecentFiles()
                          .animate()
                          .slideY(
                            begin: 0.3,
                            duration: AppTheme.animationSlow,
                            curve: Curves.easeOut,
                          )
                          ,
                      
                      // Quick Actions with enhanced animation
                      const QuickActions()
                          .animate()
                          .slideX(
                            begin: 0.3,
                            duration: AppTheme.animationSlow,
                            curve: Curves.easeOut,
                          )
                          ,
                      
                      // Bottom padding for better scrolling (smaller)
                      const SizedBox(height: AppTheme.spacingM),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed header pinned at the very top-most layer (over content)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  color: Colors.white,
                  child: MainHeader(title: i18n['home.header.title'] ?? 'Legisense'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Floating geometric shapes
        Positioned(
          top: 120,
          right: 30,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(
                begin: 0,
                end: 2 * 3.14159,
                duration: 20000.ms,
                curve: Curves.linear,
              ),
        ),
        Positioned(
          top: 300,
          left: 20,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 3000.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(0.8, 0.8),
                duration: 3000.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          bottom: 200,
          right: 50,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(25),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.3, 1.3),
                duration: 4000.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.3, 1.3),
                end: const Offset(1.0, 1.0),
                duration: 4000.ms,
                curve: Curves.easeInOut,
              ),
        ),
        // Floating particles
        ...List.generate(5, (index) {
          return Positioned(
            top: 150 + (index * 100),
            left: 50 + (index * 60),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(
                  duration: 2000.ms,
                  delay: (index * 500).ms,
                )
                .then()
                .fadeOut(duration: 2000.ms)
                .then()
                .fadeIn(duration: 2000.ms),
          );
        }),
      ],
    );
  }
}
