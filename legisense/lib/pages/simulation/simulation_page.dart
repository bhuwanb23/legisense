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
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Global Main Header
              const MainHeader(title: 'Simulation'),

              // Page body padding (keeps header flush)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.spacingS),

                    Text(
                      'Practice with sample legal scenarios',
                      style: AppTheme.subtitle,
                    )
                        .animate()
                        .slideX(
                          begin: -0.3,
                          duration: AppTheme.animationMedium,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),
              
              const SizedBox(height: AppTheme.spacingXL),
              
                  // Simulation Cards
                  _buildSimulationCard(
                title: 'Contract Analysis',
                subtitle: 'Learn to identify key terms and clauses',
                icon: FontAwesomeIcons.fileContract,
                color: AppTheme.primaryBlueLight,
                progress: 0.7,
                delay: 400,
              ),
              
                  const SizedBox(height: AppTheme.spacingM),
              
                  _buildSimulationCard(
                title: 'Legal Research',
                subtitle: 'Practice finding relevant case law',
                icon: FontAwesomeIcons.magnifyingGlass,
                color: AppTheme.successGreen,
                progress: 0.4,
                delay: 600,
              ),
              
                  const SizedBox(height: AppTheme.spacingM),
              
                  _buildSimulationCard(
                title: 'Document Drafting',
                subtitle: 'Create professional legal documents',
                icon: FontAwesomeIcons.penToSquare,
                color: AppTheme.warningOrange,
                progress: 0.2,
                delay: 800,
              ),
              
                  const SizedBox(height: AppTheme.spacingXL),
              
                  // Quick Start Button
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
                        duration: AppTheme.animationMedium,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: AppTheme.animationSlow, delay: 1000.ms),
                  const SizedBox(height: AppTheme.spacingL),
                ],
              ),
              // End Padding
              ),
            ],
          ),
        ),
      ),
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
