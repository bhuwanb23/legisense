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
  Map<String, dynamic>? _baseSimulationData; // Original LLM data
  Map<String, dynamic>? _dynamicSimulationData; // Calculated data based on parameters

  @override
  void initState() {
    super.initState();
    _baseSimulationData = widget.simulationData;
    
    // Initialize parameters from simulation data or use defaults
    if (_baseSimulationData != null) {
      final sessionData = _baseSimulationData!['session'] as Map<String, dynamic>?;
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
    
    // Calculate initial dynamic data
    _calculateDynamicData();
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

  void _calculateDynamicData() {
    if (_baseSimulationData == null) {
      _dynamicSimulationData = null;
      return;
    }

    // Create a deep copy of the base data
    _dynamicSimulationData = Map<String, dynamic>.from(_baseSimulationData!);
    
    // Normalize scenario inside parameters to enum if it arrived as String from backend
    if (_dynamicSimulationData!['session'] != null) {
      final session = Map<String, dynamic>.from(_dynamicSimulationData!['session']);
      final params = Map<String, dynamic>.from(session['parameters'] as Map<String, dynamic>? ?? {});
      final dynamic incomingScenario = params['scenario'];
      final SimulationScenario normalized = incomingScenario is SimulationScenario
          ? incomingScenario
          : _parseScenario(incomingScenario?.toString());
      params['scenario'] = normalized;
      session['parameters'] = params;
      _dynamicSimulationData!['session'] = session;
      _parameters = params; // keep local copy in sync
      _selectedScenario = normalized; // sync current selection
    }

    // Apply parameter-based transformations
    _applyParameterEffects();
  }

  void _applyParameterEffects() {
    if (_dynamicSimulationData == null) return;

    final dynamic scenarioRaw = _parameters['scenario'];
    final SimulationScenario scenario =
        scenarioRaw is SimulationScenario ? scenarioRaw : _parseScenario(scenarioRaw?.toString());
    final missedPayments = _parameters['missedPayments'] as int;
    final earlyTermination = _parameters['earlyTermination'] as bool;
    final delayDays = _parameters['delayDays'] as int;
    final interestRate = _parameters['interestRate'] as double;

    // Update session data
    if (_dynamicSimulationData!['session'] != null) {
      final session = Map<String, dynamic>.from(_dynamicSimulationData!['session']);
      session['scenario'] = scenario.name;
      session['parameters'] = _parameters;
      _dynamicSimulationData!['session'] = session;
    }

    // Apply scenario-specific effects
    switch (scenario) {
      case SimulationScenario.missedPayment:
        _applyMissedPaymentEffects(missedPayments, interestRate);
        break;
      case SimulationScenario.earlyTermination:
        _applyEarlyTerminationEffects(earlyTermination, delayDays);
        break;
      case SimulationScenario.normal:
        _applyNormalEffects();
        break;
    }
  }

  void _applyMissedPaymentEffects(int missedPayments, double interestRate) {
    // Increase penalty forecasts based on missed payments
    if (_dynamicSimulationData!['penalty_forecast'] != null) {
      final forecasts = List<Map<String, dynamic>>.from(_dynamicSimulationData!['penalty_forecast']);
      for (int i = 0; i < forecasts.length; i++) {
        final forecast = Map<String, dynamic>.from(forecasts[i]);
        final baseAmount = (forecast['amount'] as num? ?? 0).toDouble();
        final penaltyMultiplier = 1.0 + (missedPayments * 0.5); // 50% increase per missed payment
        final interestMultiplier = 1.0 + (interestRate / 100.0);
        forecast['amount'] = (baseAmount * penaltyMultiplier * interestMultiplier).round();
        forecasts[i] = forecast;
      }
      _dynamicSimulationData!['penalty_forecast'] = forecasts;
    }

    // Add risk alerts for missed payments
    if (_dynamicSimulationData!['risk_alerts'] != null) {
      final alerts = List<Map<String, dynamic>>.from(_dynamicSimulationData!['risk_alerts']);
      if (missedPayments > 0) {
        alerts.add({
          'level': missedPayments > 3 ? 'high' : 'medium',
          'message': '⚠️ $missedPayments missed payment${missedPayments > 1 ? 's' : ''} detected. Penalties and interest charges apply.',
        });
      }
      _dynamicSimulationData!['risk_alerts'] = alerts;
    }

    // Update narratives to reflect missed payments
    if (_dynamicSimulationData!['narratives'] != null) {
      final narratives = List<Map<String, dynamic>>.from(_dynamicSimulationData!['narratives']);
      for (int i = 0; i < narratives.length; i++) {
        final narrative = Map<String, dynamic>.from(narratives[i]);
        if (missedPayments > 0) {
          narrative['title'] = '${narrative['title']} (With $missedPayments Missed Payment${missedPayments > 1 ? 's' : ''})';
          narrative['severity'] = missedPayments > 2 ? 'high' : 'medium';
        }
        narratives[i] = narrative;
      }
      _dynamicSimulationData!['narratives'] = narratives;
    }
  }

  void _applyEarlyTerminationEffects(bool earlyTermination, int delayDays) {
    if (!earlyTermination) return;

    // Increase exit comparison penalties
    if (_dynamicSimulationData!['exit_comparisons'] != null) {
      final comparisons = List<Map<String, dynamic>>.from(_dynamicSimulationData!['exit_comparisons']);
      for (int i = 0; i < comparisons.length; i++) {
        final comparison = Map<String, dynamic>.from(comparisons[i]);
        final penaltyText = comparison['penalty_text'] as String? ?? '';
        if (penaltyText.contains('₹')) {
          // Extract and increase penalty amount
          final regex = RegExp(r'₹([\d,]+)');
          final match = regex.firstMatch(penaltyText);
          if (match != null) {
            final amount = int.tryParse(match.group(1)?.replaceAll(',', '') ?? '0') ?? 0;
            final increasedAmount = (amount * 1.5).round(); // 50% increase for early termination
            comparison['penalty_text'] = penaltyText.replaceAll(match.group(0)!, '₹${increasedAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}');
            comparison['risk_level'] = 'high';
          }
        }
        comparisons[i] = comparison;
      }
      _dynamicSimulationData!['exit_comparisons'] = comparisons;
    }

    // Add delay-based effects
    if (delayDays > 0) {
      if (_dynamicSimulationData!['risk_alerts'] != null) {
        final alerts = List<Map<String, dynamic>>.from(_dynamicSimulationData!['risk_alerts']);
        alerts.add({
          'level': delayDays > 30 ? 'high' : 'medium',
          'message': '⏰ Early termination with $delayDays day${delayDays > 1 ? 's' : ''} delay. Additional penalties may apply.',
        });
        _dynamicSimulationData!['risk_alerts'] = alerts;
      }
    }
  }

  void _applyNormalEffects() {
    // Reset to base values for normal scenario
    _dynamicSimulationData = Map<String, dynamic>.from(_baseSimulationData!);
    if (_dynamicSimulationData!['session'] != null) {
      final session = Map<String, dynamic>.from(_dynamicSimulationData!['session']);
      session['scenario'] = 'normal';
      session['parameters'] = _parameters;
      _dynamicSimulationData!['session'] = session;
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dynamic indicator
                          if (_parameters['scenario'] != SimulationScenario.normal || 
                              _parameters['missedPayments'] > 0 || 
                              _parameters['earlyTermination'] == true ||
                              _parameters['delayDays'] > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: const Color(0xFF8B5CF6),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Dynamic simulation active - Parameters affecting outcomes',
                                      style: TextStyle(
                                        color: const Color(0xFF8B5CF6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          EnhancedScenarioControls(
                            selectedScenario: _selectedScenario,
                            onScenarioChanged: (scenario) {
                              setState(() {
                                _selectedScenario = scenario;
                                _parameters['scenario'] = scenario;
                                _calculateDynamicData(); // Recalculate with new scenario
                              });
                            },
                            onParametersChanged: (parameters) {
                              setState(() {
                                _parameters = parameters;
                                _calculateDynamicData(); // Recalculate with new parameters
                              });
                            },
                          ),
                        ],
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
                            simulationData: _dynamicSimulationData,
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
                        jurisdiction: _dynamicSimulationData?['session']?['jurisdiction'] ?? 'Maharashtra, India',
                        message: _dynamicSimulationData?['session']?['jurisdiction_note'] ?? 
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
                        simulationData: _dynamicSimulationData,
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
                        simulationData: _dynamicSimulationData,
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
                        simulationData: _dynamicSimulationData,
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
                        simulationData: _dynamicSimulationData,
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
                        simulationData: _dynamicSimulationData,
                      ),
                    )
                        .animate()
                        .slideY(begin: 0.2, duration: AppTheme.animationSlow, curve: Curves.easeOut)
                        .fadeIn(duration: AppTheme.animationSlow, delay: 600.ms),

                    const SizedBox(height: 16),

                    // Export section
                    _section(
                      ExportOptions(documentTitle: widget.documentTitle),
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
