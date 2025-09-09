import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'document_list.dart';
import '../../components/main_header.dart';
import '../../theme/app_theme.dart';
// Only list on this page; detail is a separate route

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // blue-50
              Color(0xFFF5F3FF), // purple-50
              Color(0xFFF0F9FF), // sky-50
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background elements
              _buildAnimatedBackground(),
              
              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Spacer so content starts below fixed header
                  const SizedBox(height: 104),

                  // Enhanced subtitle section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingXS),
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
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
                            FontAwesomeIcons.folderOpen, 
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
                                'Document Management',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXS),
                              Text(
                                'Browse, analyze, and manage your legal documents',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingS,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(
                              color: AppTheme.successGreen.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Active',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.successGreen,
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

                  // Enhanced list layout
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double width = constraints.maxWidth;
                          final bool isWide = width >= 600;

                          final Widget list = const DocumentListPanel();

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 100, child: list),
                              ],
                            );
                          }

                          return list;
                        },
                      ),
                    ),
                  )
                      .animate()
                      .slideY(
                        begin: 0.3,
                        duration: AppTheme.animationSlow,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(duration: AppTheme.animationSlow, delay: 400.ms),
                ],
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
                    child: const MainHeader(title: 'Documents'),
                  ),
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
        // Floating circles
        Positioned(
          top: 100,
          left: 50,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
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
          top: 200,
          right: 80,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.successGreen.withValues(alpha: 0.1),
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
        Positioned(
          bottom: 150,
          left: 100,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.warningOrange.withValues(alpha: 0.1),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.4, 1.4),
                duration: 3500.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.4, 1.4),
                end: const Offset(0.9, 0.9),
                duration: 3500.ms,
                curve: Curves.easeInOut,
              ),
        ),
      ],
    );
  }
}
