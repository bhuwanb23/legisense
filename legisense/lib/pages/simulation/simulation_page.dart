import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../components/main_header.dart';
import 'components/components.dart';
import 'enhanced_simulation_details.dart';

class SimulationPage extends StatelessWidget {
  const SimulationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC), // slate-50
              Color(0xFFEFF6FF), // blue-50
              Color(0xFFF0F9FF), // sky-50
              Color(0xFFF5F3FF), // purple-50
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background elements
              _buildAnimatedBackground(),
              
              // Main content with fixed layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Global Main Header with enhanced animation
                  const MainHeader(title: 'Simulation')
                      .animate()
                      .slideY(
                        begin: -0.5,
                        duration: AppTheme.animationSlow,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: AppTheme.animationSlow),

                  // Enhanced subtitle section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: const Icon(
                            Icons.play_arrow, 
                            size: 16, 
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Legal Practice Simulations',
                                style: AppTheme.heading4.copyWith(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXS),
                              Text(
                                'Select a document to start simulation',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warningOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                            border: Border.all(
                              color: AppTheme.warningOrange.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Interactive',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.warningOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .slideX(
                        begin: -0.3,
                        duration: AppTheme.animationSlow,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),

                  // Document List Section - Fixed height with internal scrolling
                  Expanded(
                    child:                     DocumentListSection(
                      onDocumentTap: (documentId, documentTitle) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EnhancedSimulationDetailsPage(
                              documentId: documentId,
                              documentTitle: documentTitle,
                            ),
                          ),
                        );
                      },
                    )
                        .animate()
                        .slideY(
                          begin: 0.3,
                          duration: AppTheme.animationSlow,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Floating geometric shapes
        Positioned(
          top: 150,
          right: 50,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(30),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.3, 1.3),
                duration: 5000.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.3, 1.3),
                end: const Offset(0.8, 0.8),
                duration: 5000.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          top: 300,
          left: 40,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.05),
              shape: BoxShape.circle,
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
          bottom: 200,
          right: 80,
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.4, 1.4),
                duration: 3500.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.4, 1.4),
                end: const Offset(1.0, 1.0),
                duration: 3500.ms,
                curve: Curves.easeInOut,
              ),
        ),
        // Floating particles
        ...List.generate(4, (index) {
          return Positioned(
            top: 180 + (index * 120),
            left: 60 + (index * 70),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(
                  duration: 2000.ms,
                  delay: (index * 600).ms,
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
