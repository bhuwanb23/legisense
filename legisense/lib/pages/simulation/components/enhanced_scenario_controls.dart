import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'simulation_scenario.dart';

class EnhancedScenarioControls extends StatefulWidget {
  final SimulationScenario selectedScenario;
  final ValueChanged<SimulationScenario>? onScenarioChanged;
  final ValueChanged<Map<String, dynamic>>? onParametersChanged;
  
  const EnhancedScenarioControls({
    super.key,
    required this.selectedScenario,
    this.onScenarioChanged,
    this.onParametersChanged,
  });

  @override
  State<EnhancedScenarioControls> createState() => _EnhancedScenarioControlsState();
}

class _EnhancedScenarioControlsState extends State<EnhancedScenarioControls> {
  late SimulationScenario _selectedScenario;
  int _missedPayments = 0;
  bool _earlyTermination = false;
  int _delayDays = 0;
  double _interestRate = 2.0;

  @override
  void initState() {
    super.initState();
    _selectedScenario = widget.selectedScenario;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.sliders,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What-If Scenario Controls',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Adjust parameters to see different outcomes',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        FontAwesomeIcons.wandMagicSparkles,
                        size: 12,
                        color: Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Interactive',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Scenario Selection
            _buildScenarioSelection(),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Scenario Type',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildScenarioCard(
                scenario: SimulationScenario.normal,
                title: 'Normal Flow',
                description: 'Standard execution',
                icon: FontAwesomeIcons.check,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildScenarioCard(
                scenario: SimulationScenario.missedPayment,
                title: 'Missed Payment',
                description: 'Payment delays',
                icon: FontAwesomeIcons.clock,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildScenarioCard(
                scenario: SimulationScenario.earlyTermination,
                title: 'Early Termination',
                description: 'Contract breach',
                icon: FontAwesomeIcons.triangleExclamation,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScenarioCard({
    required SimulationScenario scenario,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedScenario == scenario;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedScenario = scenario;
        });
        widget.onScenarioChanged?.call(scenario);
        _updateParameters();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }




  void _updateParameters() {
    final parameters = {
      'scenario': _selectedScenario,
      'missedPayments': _missedPayments,
      'earlyTermination': _earlyTermination,
      'delayDays': _delayDays,
      'interestRate': _interestRate,
    };
    widget.onParametersChanged?.call(parameters);
  }
}
