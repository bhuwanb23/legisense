import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import 'components/components.dart';

class EnhancedSimulationDetailsPage extends StatefulWidget {
  final String documentId;
  final String documentTitle;
  final Map<String, dynamic>? simulationData;
  
  const EnhancedSimulationDetailsPage({
    super.key,
    required this.documentId,
    required this.documentTitle,
    this.simulationData,
  });

  @override
  State<EnhancedSimulationDetailsPage> createState() => _EnhancedSimulationDetailsPageState();
}

class _EnhancedSimulationDetailsPageState extends State<EnhancedSimulationDetailsPage> {
  SimulationScenario _selectedScenario = SimulationScenario.normal;
  Map<String, dynamic> _parameters = {};
  Map<String, dynamic>? _simulationData;

  @override
  void initState() {
    super.initState();
    _simulationData = widget.simulationData;
    
    // Initialize parameters from simulation data or use defaults
    if (_simulationData != null) {
      final sessionData = _simulationData!['session'] as Map<String, dynamic>?;
      if (sessionData != null) {
        _selectedScenario = _parseScenario(sessionData['scenario'] as String?);
        _parameters = Map<String, dynamic>.from(sessionData['parameters'] as Map<String, dynamic>? ?? {});
      }
    }
    
    // Set defaults if no simulation data
    if (_parameters.isEmpty) {
      _parameters = {
        'scenario': _selectedScenario,
        'missedPayments': 0,
        'earlyTermination': false,
        'delayDays': 0,
        'interestRate': 2.0,
      };
    }
  }

  SimulationScenario _parseScenario(String? scenario) {
    switch (scenario?.toLowerCase()) {
      case 'missedpayment':
      case 'missed_payment':
        return SimulationScenario.missedPayment;
      case 'earlytermination':
      case 'early_termination':
        return SimulationScenario.earlyTermination;
      default:
        return SimulationScenario.normal;
    }
  }

  Widget _section(Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
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
              
              // Main content with scrolling below fixed header
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 120),

                    // Enhanced Scenario Controls section
                    _section(
                      EnhancedScenarioControls(
                        selectedScenario: _selectedScenario,
                        onScenarioChanged: (scenario) {
                          setState(() {
                            _selectedScenario = scenario;
                            _parameters['scenario'] = scenario;
                          });
                        },
                        onParametersChanged: (parameters) {
                          setState(() {
                            _parameters = parameters;
                          });
                        },
                      ),
                    )
                        .animate()
                        .slideX(begin: -0.2, duration: AppTheme.animationSlow, curve: Curves.easeOut)
                        .fadeIn(duration: AppTheme.animationSlow, delay: 150.ms),

                    const SizedBox(height: 16),

                    // Legend + Timeline section
                    _section(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LegendBar(),
                          const SizedBox(height: 12),
                          TimelineView(
                            scenario: _selectedScenario,
                            documentTitle: widget.documentTitle,
                            simulationData: _simulationData,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .slideY(begin: 0.2, duration: AppTheme.animationSlow, curve: Curves.easeOut)
                        .fadeIn(duration: AppTheme.animationSlow, delay: 300.ms),

                    const SizedBox(height: 16),

                    // Jurisdiction notice section
                    _section(
                      JurisdictionNotice(
                        jurisdiction: _simulationData?['session']?['jurisdiction'] ?? 'Maharashtra, India',
                        message: _simulationData?['session']?['jurisdiction_note'] ?? 
                            'Even though contract says 15-day eviction, local law requires 30 days. Timeline and outcomes adjusted accordingly.',
                      ),
                    )
                        .animate()
                        .slideX(begin: -0.15, duration: AppTheme.animationSlow, curve: Curves.easeOut)
                        .fadeIn(duration: AppTheme.animationSlow, delay: 375.ms),

                    const SizedBox(height: 16),

                    // Penalty & Liability Forecast
                    _section(
                      PenaltyForecastPanel(
                        documentTitle: widget.documentTitle,
                        parameters: _parameters,
                        simulationData: _simulationData,
                      ),
                    )
                        .animate()
                        .slideY(begin: 0.15, duration: AppTheme.animationSlow, curve: Curves.easeOut)
                        .fadeIn(duration: AppTheme.animationSlow, delay: 420.ms),

                    const SizedBox(height: 16),

                    // Termination / Exit Comparison
                    _section(
                      ComparisonPanel(
                        documentTitle: widget.documentTitle,
                        simulationData: _simulationData,
                      ),
                    )
                        .animate()
                        .slideX(begin: 0.15, duration: AppTheme.animationSlow, curve: Curves.easeOut)
                        .fadeIn(duration: AppTheme.animationSlow, delay: 480.ms),

                    const SizedBox(height: 16),

                    // Long-term forecast
                    _section(
                      LongTermForecastChart(
                        documentTitle: widget.documentTitle,
                        parameters: _parameters,
                        simulationData: _simulationData,
                      ),
                    )
                        .animate()
                        .slideY(begin: 0.15, duration: AppTheme.animationSlow, curve: Curves.easeOut)
                        .fadeIn(duration: AppTheme.animationSlow, delay: 540.ms),

                    // Risk Alerts section
                    _section(
                      RiskAlerts(
                        scenario: _selectedScenario,
                        documentTitle: widget.documentTitle,
                        simulationData: _simulationData,
                      ),
                    )
                        .animate()
                        .slideX(begin: 0.2, duration: AppTheme.animationSlow, curve: Curves.easeOut)
                        .fadeIn(duration: AppTheme.animationSlow, delay: 450.ms),

                    const SizedBox(height: 16),

                    // Narrative Outcome Cards section
                    _section(
                      NarrativeOutcomeCards(
                        scenario: _selectedScenario,
                        parameters: _parameters,
                        simulationData: _simulationData,
                      ),
                    )
                        .animate()
                        .slideY(begin: 0.2, duration: AppTheme.animationSlow, curve: Curves.easeOut)
                        .fadeIn(duration: AppTheme.animationSlow, delay: 600.ms),

                    const SizedBox(height: 16),

                    // Export + Next Steps section
                    _section(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ExportOptions(),
                          const SizedBox(height: 12),
                          NextStepsCTA(
                            documentTitle: widget.documentTitle,
                            onBackToAnalysis: () => Navigator.of(context).pop(),
                            onSaveSimulation: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Simulation saved for ${widget.documentTitle}!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            },
                            onExportReport: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Report exported for ${widget.documentTitle}!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            },
                            onShareResults: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Results shared for ${widget.documentTitle}!'),
                                  backgroundColor: const Color(0xFF8B5CF6),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .slideY(begin: 0.2, duration: AppTheme.animationSlow, curve: Curves.easeOut)
                        .fadeIn(duration: AppTheme.animationSlow, delay: 750.ms),

                    const SizedBox(height: 8),
                  ],
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
                    child: DocumentHeader(
                      documentTitle: widget.documentTitle,
                      documentVersion: 'V2.1',
                      onBackPressed: () => Navigator.of(context).pop(),
                      availableDocuments: const [], // hide switch document dropdown
                    ),
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
