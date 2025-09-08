import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import 'components/components.dart';

class SimulationDetailsPage extends StatefulWidget {
  final String documentId;
  final String documentTitle;
  
  const SimulationDetailsPage({
    super.key,
    required this.documentId,
    required this.documentTitle,
  });

  @override
  State<SimulationDetailsPage> createState() => _SimulationDetailsPageState();
}

class _SimulationDetailsPageState extends State<SimulationDetailsPage> {
  SimulationScenario _selectedScenario = SimulationScenario.normal;

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
              
              // Main content with scrolling
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Simulation Header
                    SimulationHeader(
                      title: 'Contract Simulation',
                      subtitle: '${widget.documentTitle} - V2.1',
                      onBackPressed: () => Navigator.of(context).pop(),
                    )
                        .animate()
                        .slideY(
                          begin: -0.5,
                          duration: AppTheme.animationSlow,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: AppTheme.animationSlow),

                    const SizedBox(height: 24),

                    // Scenario Controls
                    ScenarioControls(
                      selectedScenario: _selectedScenario,
                      onScenarioChanged: (scenario) {
                        setState(() {
                          _selectedScenario = scenario;
                        });
                      },
                    )
                        .animate()
                        .slideX(
                          begin: -0.3,
                          duration: AppTheme.animationSlow,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),

                    const SizedBox(height: 24),

                    // Interactive Flowchart
                    InteractiveFlowchart(
                      scenario: _selectedScenario,
                    )
                        .animate()
                        .slideY(
                          begin: 0.3,
                          duration: AppTheme.animationSlow,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: AppTheme.animationSlow, delay: 400.ms),

                    const SizedBox(height: 24),

                    // Outcome Cards
                    OutcomeCards(
                      scenario: _selectedScenario,
                    )
                        .animate()
                        .slideY(
                          begin: 0.3,
                          duration: AppTheme.animationSlow,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: AppTheme.animationSlow, delay: 600.ms),

                    const SizedBox(height: 24),

                    // Action Buttons
                    ActionButtons(
                      onRunSimulation: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Simulation started for ${widget.documentTitle}!'),
                            backgroundColor: const Color(0xFF2563EB),
                          ),
                        );
                      },
                      onExportReport: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Report exported for ${widget.documentTitle}!'),
                            backgroundColor: const Color(0xFF16A34A),
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
                        .fadeIn(duration: AppTheme.animationSlow, delay: 800.ms),

                    const SizedBox(height: 24),
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
