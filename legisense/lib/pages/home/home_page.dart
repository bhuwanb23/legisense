import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'components/components.dart';
import '../../components/main_header.dart';
import '../../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _onRefresh() async {
    // Trigger refresh of RecentFiles component
    // The RecentFiles component will handle its own refresh logic
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
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
            
            // Main content with pull-to-refresh
            SafeArea(
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _onRefresh,
                color: AppTheme.primaryBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Global Main Header with enhanced animation
                      const MainHeader(title: 'Legisense')
                          .animate()
                          .slideY(
                            begin: -0.5,
                            duration: AppTheme.animationSlow,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: AppTheme.animationSlow),
                      
                      // Welcome Section with staggered animation
                      const WelcomeSection()
                          .animate()
                          .slideX(
                            begin: -0.3,
                            duration: AppTheme.animationSlow,
                            curve: Curves.easeOut,
                          )
                          .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),
                      
                      // Upload Zone with enhanced animation
                      const UploadZone()
                          .animate()
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            duration: AppTheme.animationSlow,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: AppTheme.animationSlow, delay: 400.ms),
                      
                      // Recent Files with slide animation
                      const RecentFiles()
                          .animate()
                          .slideY(
                            begin: 0.3,
                            duration: AppTheme.animationSlow,
                            curve: Curves.easeOut,
                          )
                          .fadeIn(duration: AppTheme.animationSlow, delay: 600.ms),
                      
                      // Quick Actions with enhanced animation
                      const QuickActions()
                          .animate()
                          .slideX(
                            begin: 0.3,
                            duration: AppTheme.animationSlow,
                            curve: Curves.easeOut,
                          )
                          .fadeIn(duration: AppTheme.animationSlow, delay: 800.ms),
                      
                      // Bottom padding for better scrolling
                      const SizedBox(height: AppTheme.spacingL),
                    ],
                  ),
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
