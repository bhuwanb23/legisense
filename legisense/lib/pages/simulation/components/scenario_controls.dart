import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

enum SimulationScenario {
  normal,
  missedPayment,
  earlyTermination,
}

class ScenarioControls extends StatefulWidget {
  final SimulationScenario selectedScenario;
  final ValueChanged<SimulationScenario>? onScenarioChanged;

  const ScenarioControls({
    super.key,
    required this.selectedScenario,
    this.onScenarioChanged,
  });

  @override
  State<ScenarioControls> createState() => _ScenarioControlsState();
}

class _ScenarioControlsState extends State<ScenarioControls> {
  late SimulationScenario _selectedScenario;

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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDBEAFE), // blue-100
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.sliders,
                    color: Color(0xFF2563EB),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'What If Scenarios',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Scenario options
            Column(
              children: [
                _buildScenarioOption(
                  scenario: SimulationScenario.normal,
                  title: 'Normal Contract Flow',
                  description: 'Standard contract execution',
                  color: const Color(0xFFEFF6FF), // blue-50
                  borderColor: const Color(0xFFBFDBFE), // blue-200
                  iconColor: const Color(0xFF2563EB),
                ),
                
                const SizedBox(height: 12),
                
                _buildScenarioOption(
                  scenario: SimulationScenario.missedPayment,
                  title: 'Miss Payment Deadline',
                  description: 'Payment delay scenario',
                  color: const Color(0xFFFFF7ED), // orange-50
                  borderColor: const Color(0xFFFED7AA), // orange-200
                  iconColor: const Color(0xFFF59E0B),
                ),
                
                const SizedBox(height: 12),
                
                _buildScenarioOption(
                  scenario: SimulationScenario.earlyTermination,
                  title: 'Early Termination',
                  description: 'Contract breach scenario',
                  color: const Color(0xFFFEF2F2), // red-50
                  borderColor: const Color(0xFFFECACA), // red-200
                  iconColor: const Color(0xFFEF4444),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioOption({
    required SimulationScenario scenario,
    required String title,
    required String description,
    required Color color,
    required Color borderColor,
    required Color iconColor,
  }) {
    final isSelected = _selectedScenario == scenario;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedScenario = scenario;
          });
          widget.onScenarioChanged?.call(scenario);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? borderColor : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Radio button
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? iconColor : const Color(0xFFD1D5DB),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
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
}
