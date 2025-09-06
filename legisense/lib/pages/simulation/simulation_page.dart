import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../components/main_header.dart';
import '../../theme/app_theme.dart';

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
              
              // Main content
              SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
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
                      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL, vertical: AppTheme.spacingM),
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
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
                              FontAwesomeIcons.play, 
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
                                  'Practice with sample legal scenarios and improve your skills',
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

                    // Page body padding (keeps header flush)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.spacingS),
              
                          const SizedBox(height: AppTheme.spacingXL),
              
                          // Simulation Cards with enhanced animations
                          _buildSimulationCard(
                            title: 'Contract Analysis',
                            subtitle: 'Learn to identify key terms and clauses',
                            icon: FontAwesomeIcons.fileContract,
                            color: AppTheme.primaryBlueLight,
                            progress: 0.7,
                            delay: 400,
                          )
                              .animate()
                              .slideX(
                                begin: -0.3,
                                duration: AppTheme.animationSlow,
                                curve: Curves.easeOut,
                              )
                              .fadeIn(duration: AppTheme.animationSlow, delay: 400.ms),
                          
                          const SizedBox(height: AppTheme.spacingM),
                          
                          _buildSimulationCard(
                            title: 'Legal Research',
                            subtitle: 'Practice finding relevant case law',
                            icon: FontAwesomeIcons.magnifyingGlass,
                            color: AppTheme.successGreen,
                            progress: 0.4,
                            delay: 600,
                          )
                              .animate()
                              .slideX(
                                begin: 0.3,
                                duration: AppTheme.animationSlow,
                                curve: Curves.easeOut,
                              )
                              .fadeIn(duration: AppTheme.animationSlow, delay: 600.ms),
                          
                          const SizedBox(height: AppTheme.spacingM),
                          
                          _buildSimulationCard(
                            title: 'Document Drafting',
                            subtitle: 'Create professional legal documents',
                            icon: FontAwesomeIcons.penToSquare,
                            color: AppTheme.warningOrange,
                            progress: 0.2,
                            delay: 800,
                          )
                              .animate()
                              .slideX(
                                begin: -0.3,
                                duration: AppTheme.animationSlow,
                                curve: Curves.easeOut,
                              )
                              .fadeIn(duration: AppTheme.animationSlow, delay: 800.ms),
                          
                          const SizedBox(height: AppTheme.spacingXL),
              
                          // Quick Start Button with enhanced animation
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.successGreen,
                                  Color(0xFF059669),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.successGreen.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Starting a new simulation...'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      FontAwesomeIcons.play,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppTheme.spacingM),
                                    Text(
                                      'Start New Simulation',
                                      style: AppTheme.buttonPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                duration: AppTheme.animationSlow,
                                curve: Curves.elasticOut,
                              )
                              .fadeIn(duration: AppTheme.animationSlow, delay: 1000.ms),
                          
                          const SizedBox(height: AppTheme.spacingL),
                        ],
                      ),
                    ),
                  ],
                ),
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(50),
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
            width: 70,
            height: 70,
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

  Widget _buildSimulationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: AppTheme.spacingM),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.heading4,
                    ),
                    
                    const SizedBox(height: AppTheme.spacingXS),
                    
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingXS),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTheme.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideX(
          begin: 0.3,
          duration: AppTheme.animationMedium,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: AppTheme.animationSlow, delay: delay.ms);
  }
}
