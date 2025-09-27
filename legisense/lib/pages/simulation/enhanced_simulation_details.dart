import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import 'components/components.dart';
import '../profile/language/language_scope.dart';
import 'language/strings.dart';
import '../../api/parsed_documents_repository.dart';
import 'dart:developer' as developer;

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
  bool _isTranslating = false;
  bool _isInitialLoading = true; // New flag for initial loading
  String? _currentLanguage;
  late ParsedDocumentsRepository _repository;
  Map<String, dynamic>? _englishSnapshot; // Snapshot to compare for translation
  int _translationAttempts = 0;

  @override
  void initState() {
    super.initState();
    _repository = ParsedDocumentsRepository(baseUrl: ApiConfig.baseUrl);
    _baseSimulationData = widget.simulationData;
    _englishSnapshot = widget.simulationData != null
        ? Map<String, dynamic>.from(widget.simulationData!)
        : null;
    
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
    
    // Check if we need to load translated data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final scope = LanguageScope.maybeOf(context);
        final currentLanguage = scope?.language.name ?? 'en';
        developer.log('🧪 Initial language check: $currentLanguage', name: 'EnhancedSimulationDetailsPage');
        
        if (currentLanguage != 'en') {
          developer.log('🌐 Loading translated data immediately for language: $currentLanguage', name: 'EnhancedSimulationDetailsPage');
          _loadTranslatedSimulationData(currentLanguage);
        } else {
          // No translation needed, hide loading
          setState(() {
            _isInitialLoading = false;
          });
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = LanguageScope.maybeOf(context);
    final newLanguage = scope?.language.name ?? 'en';
    
    developer.log('🔄 didChangeDependencies: currentLanguage=$_currentLanguage, newLanguage=$newLanguage', name: 'EnhancedSimulationDetailsPage');
    
    if (_currentLanguage != null && _currentLanguage != newLanguage) {
      developer.log('🌐 Language changed from $_currentLanguage to $newLanguage, loading translation...', name: 'EnhancedSimulationDetailsPage');
      
      if (newLanguage == 'en') {
        // Switching to English - show original data immediately
        developer.log('🔄 Switching to English - showing original data', name: 'EnhancedSimulationDetailsPage');
        setState(() {
          _isTranslating = false;
          _isInitialLoading = false;
          // Reset to original data
          _baseSimulationData = widget.simulationData;
          _calculateDynamicData();
        });
      } else {
        // Switching to non-English - show loader and translate
        developer.log('🌐 Switching to $newLanguage - showing loader and translating', name: 'EnhancedSimulationDetailsPage');
        setState(() {
          _isTranslating = true;
          _isInitialLoading = true;
        });
        
        _loadTranslatedSimulationData(newLanguage);
      }
    }
    _currentLanguage = newLanguage;
  }

  Future<void> _loadTranslatedSimulationData(String language) async {
    if (_baseSimulationData == null) {
      developer.log('❌ No base simulation data available', name: 'EnhancedSimulationDetailsPage');
      setState(() {
        _isTranslating = false;
        _isInitialLoading = false;
      });
      return;
    }
    
    developer.log('📊 Base simulation data keys: ${_baseSimulationData!.keys.toList()}', name: 'EnhancedSimulationDetailsPage');
    if (_baseSimulationData!['session'] != null) {
      developer.log('📋 Session data keys: ${(_baseSimulationData!['session'] as Map).keys.toList()}', name: 'EnhancedSimulationDetailsPage');
    }
    
    final sessionId = _baseSimulationData!['session']?['id'] as int?;
    if (sessionId == null) {
      developer.log('❌ No session ID found in simulation data', name: 'EnhancedSimulationDetailsPage');
      developer.log('📊 Available session data: ${_baseSimulationData!['session']}', name: 'EnhancedSimulationDetailsPage');
      setState(() {
        _isTranslating = false;
        _isInitialLoading = false;
      });
      return;
    }

    developer.log('🔄 Starting translation for session $sessionId to language $language', name: 'EnhancedSimulationDetailsPage');
    
    setState(() {
      _isTranslating = true;
      _isInitialLoading = true; // Keep initial loading true during translation
    });

    try {
      final translatedData = await _repository.fetchSimulationWithLanguage(
        sessionId: sessionId,
        language: language,
      );

      developer.log('✅ Translation response received for session $sessionId', name: 'EnhancedSimulationDetailsPage');

      // Verify translated content before displaying
      final looksTranslated = _looksTranslated(translatedData, language);
      developer.log('🔎 looksTranslated=$looksTranslated (attempt ${_translationAttempts + 1})', name: 'EnhancedSimulationDetailsPage');

      if (!looksTranslated && _translationAttempts < 10) {
        _translationAttempts += 1;
        // keep loader visible and retry shortly
        await Future.delayed(const Duration(milliseconds: 900));
        return _loadTranslatedSimulationData(language);
      }

      _translationAttempts = 0; // reset attempts on success or give up

      setState(() {
        _baseSimulationData = translatedData;
        _calculateDynamicData();
        _isTranslating = false;
        _isInitialLoading = false; // Hide loading when translation is complete
      });
    } catch (e) {
      developer.log('❌ Translation failed for session $sessionId: $e', name: 'EnhancedSimulationDetailsPage');
      setState(() {
        _isTranslating = false;
        _isInitialLoading = false; // Hide loading even if translation fails
      });
      // Keep original data if translation fails
    }
  }

  bool _looksTranslated(Map<String, dynamic> data, String language) {
    if (language == 'en') return true;
    // Compare against English snapshot if available
    try {
      final session = data['session'] as Map<String, dynamic>?;
      final enSession = _englishSnapshot?['session'] as Map<String, dynamic>?;
      final title = session?['title']?.toString() ?? '';
      final enTitle = enSession?['title']?.toString() ?? '';
      if (title.isNotEmpty && enTitle.isNotEmpty && title != enTitle) {
        return true;
      }

      // Check first narrative title/body differences
      final narratives = (data['narratives'] as List?)?.cast<dynamic>() ?? const [];
      final enNarratives = (_englishSnapshot?['narratives'] as List?)?.cast<dynamic>() ?? const [];
      if (narratives.isNotEmpty && enNarratives.isNotEmpty) {
        final t0 = (narratives.first as Map)['title']?.toString() ?? '';
        final e0 = (enNarratives.first as Map)['title']?.toString() ?? '';
        if (t0.isNotEmpty && e0.isNotEmpty && t0 != e0) return true;
      }

      // Check first risk alert message difference
      final risks = (data['risk_alerts'] as List?)?.cast<dynamic>() ?? const [];
      final enRisks = (_englishSnapshot?['risk_alerts'] as List?)?.cast<dynamic>() ?? const [];
      if (risks.isNotEmpty && enRisks.isNotEmpty) {
        final t0 = (risks.first as Map)['message']?.toString() ?? '';
        final e0 = (enRisks.first as Map)['message']?.toString() ?? '';
        if (t0.isNotEmpty && e0.isNotEmpty && t0 != e0) return true;
      }

      // Heuristic: for Indian languages expect non-ascii chars
      final sample = [
        title,
        if ((risks).isNotEmpty) (risks.first as Map)['message']?.toString() ?? '',
        if ((narratives).isNotEmpty) (narratives.first as Map)['narrative']?.toString() ?? '',
      ].firstWhere((s) => s.isNotEmpty, orElse: () => '');
      if (language != 'en' && sample.isNotEmpty) {
        final hasNonAscii = sample.codeUnits.any((u) => u > 127);
        if (hasNonAscii) return true;
      }
    } catch (_) {
      // If structure unexpected, don't block UI indefinitely
      return true;
    }
    return false;
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
    
    developer.log('🔄 _calculateDynamicData: Keys in base data: ${_baseSimulationData!.keys.toList()}', name: 'EnhancedSimulationDetailsPage');
    developer.log('🔄 _calculateDynamicData: Keys in dynamic data: ${_dynamicSimulationData!.keys.toList()}', name: 'EnhancedSimulationDetailsPage');
    
    // Check if we have translated content
    if (_baseSimulationData!['risk_alerts'] != null) {
      final riskAlerts = _baseSimulationData!['risk_alerts'] as List<dynamic>?;
      if (riskAlerts != null && riskAlerts.isNotEmpty) {
        developer.log('📊 Risk alerts count: ${riskAlerts.length}', name: 'EnhancedSimulationDetailsPage');
        for (int i = 0; i < riskAlerts.length; i++) {
          final alert = riskAlerts[i] as Map<String, dynamic>;
          developer.log('📊 Risk alert $i: level=${alert['level']}, message=${alert['message']?.toString().substring(0, 50)}...', name: 'EnhancedSimulationDetailsPage');
        }
      }
    }
    
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
    
    // Trigger UI update after data calculation
    if (mounted) {
      setState(() {
        // This will trigger a rebuild of the UI with the new data
        developer.log('🔄 UI update triggered after data calculation', name: 'EnhancedSimulationDetailsPage');
      });
    }
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

  /// Manually refresh the simulation data and trigger UI update
  void refreshSimulationData() {
    developer.log('🔄 Manual refresh triggered', name: 'EnhancedSimulationDetailsPage');
    _calculateDynamicData();
  }

  /// Force UI update with current data
  void forceUIUpdate() {
    if (mounted) {
      setState(() {
        developer.log('🔄 Force UI update triggered', name: 'EnhancedSimulationDetailsPage');
      });
    }
  }

  /// Update specific parameter and trigger UI refresh
  void updateParameter(String key, dynamic value) {
    if (mounted) {
      setState(() {
        _parameters[key] = value;
        developer.log('🔄 Parameter updated: $key = $value', name: 'EnhancedSimulationDetailsPage');
        _calculateDynamicData();
      });
    }
  }

  /// Update scenario and trigger UI refresh
  void updateScenario(SimulationScenario scenario) {
    if (mounted) {
      setState(() {
        _selectedScenario = scenario;
        _parameters['scenario'] = scenario;
        developer.log('🔄 Scenario updated: $scenario', name: 'EnhancedSimulationDetailsPage');
        _calculateDynamicData();
      });
    }
  }

  Widget _section(Widget child) {
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
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
                key: ValueKey('simulation_content_${_dynamicSimulationData?.hashCode ?? 0}'),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 120),

                    // Show loading indicator if translating or initial loading
                    if (_isTranslating || _isInitialLoading) _buildTranslationLoader(i18n),

                    // Debug: Manual translation trigger button (remove in production)
                    if (!_isTranslating && !_isInitialLoading) _buildDebugTranslationButton(i18n),

                    // Only show content when not loading
                    if (!_isInitialLoading) ...[

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
                                      i18n['dynamic.active'] ?? 'Dynamic simulation active - Parameters affecting outcomes',
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
                    ], // Close the conditional content block
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

  Widget _buildTranslationLoader(Map<String, String> i18n) {
    final isInitialLoad = _isInitialLoading && !_isTranslating;
    final title = isInitialLoad 
        ? (i18n['translation.initial'] ?? 'Loading simulation data...')
        : (i18n['translation.loading'] ?? 'Translating simulation data...');
    final subtitle = isInitialLoad
        ? 'Please wait while we load the simulation content in your selected language.'
        : 'Please wait while we translate the simulation content to your selected language.';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.primaryBlue.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugTranslationButton(Map<String, String> i18n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final scope = LanguageScope.maybeOf(context);
                    final currentLanguage = scope?.language.name ?? 'en';
                    if (currentLanguage != 'en') {
                      setState(() {
                        _isTranslating = true;
                        _isInitialLoading = true;
                      });
                      _loadTranslatedSimulationData(currentLanguage);
                    }
                  },
                  icon: const Icon(Icons.translate, size: 16),
                  label: Text('If not translated then click here (${LanguageScope.maybeOf(context)?.language.name ?? 'en'})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  refreshSimulationData();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh UI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current Language: ${LanguageScope.maybeOf(context)?.language.name ?? 'en'} | Previous: $_currentLanguage',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'Data Hash: ${_dynamicSimulationData?.hashCode ?? 0} | Parameters: ${_parameters.toString()}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
