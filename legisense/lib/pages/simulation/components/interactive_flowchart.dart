import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'scenario_controls.dart';

class InteractiveFlowchart extends StatelessWidget {
  final SimulationScenario scenario;
  
  const InteractiveFlowchart({
    super.key,
    required this.scenario,
  });

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
                    FontAwesomeIcons.sitemap,
                    color: Color(0xFF2563EB),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Contract Timeline',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Timeline stages
            Column(
              children: [
                _buildStage(
                  stageNumber: 1,
                  title: 'Contract Signing',
                  description: 'Initial obligations and terms established',
                  color: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFF2563EB),
                  delay: 0,
                ),
                
                _buildArrow(delay: 200),
                
                _buildStage(
                  stageNumber: 2,
                  title: 'Payment Due',
                  description: 'Monthly payment of \$2,500 required',
                  color: const Color(0xFFF59E0B),
                  backgroundColor: const Color(0xFFFFF7ED),
                  borderColor: const Color(0xFFF59E0B),
                  delay: 400,
                  warning: 'Warning: Late fees apply after 15 days',
                  warningIcon: FontAwesomeIcons.triangleExclamation,
                ),
                
                _buildArrow(delay: 600),
                
                _buildStage(
                  stageNumber: 3,
                  title: 'Risk Assessment',
                  description: 'Potential contract breach consequences',
                  color: const Color(0xFFEF4444),
                  backgroundColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFEF4444),
                  delay: 800,
                  warning: 'High Risk: Legal action possible',
                  warningIcon: FontAwesomeIcons.shield,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage({
    required int stageNumber,
    required String title,
    required String description,
    required Color color,
    required Color backgroundColor,
    required Color borderColor,
    required int delay,
    String? warning,
    IconData? warningIcon,
  }) {
    return Row(
      children: [
        // Stage number circle
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              stageNumber.toString(),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        )
            .animate(delay: delay.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              duration: 600.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 600.ms),
        
        const SizedBox(width: 16),
        
        // Stage content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: borderColor,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                if (warning != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        warningIcon ?? FontAwesomeIcons.triangleExclamation,
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          warning,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          )
              .animate(delay: (delay + 200).ms)
              .slideX(
                begin: 0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 600.ms),
        ),
      ],
    );
  }

  Widget _buildArrow({required int delay}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Icon(
          FontAwesomeIcons.arrowDown,
          color: const Color(0xFF2563EB),
          size: 20,
        )
            .animate(delay: delay.ms)
            .slideY(
              begin: 0.5,
              duration: 400.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(duration: 400.ms),
      ),
    );
  }
}

