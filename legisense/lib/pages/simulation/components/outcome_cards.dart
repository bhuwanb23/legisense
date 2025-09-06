import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'scenario_controls.dart';

class OutcomeCards extends StatelessWidget {
  final SimulationScenario scenario;
  
  const OutcomeCards({
    super.key,
    required this.scenario,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                FontAwesomeIcons.lightbulb,
                color: Color(0xFF2563EB),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Predicted Outcomes',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Outcome cards based on scenario
        ..._buildOutcomeCardsForScenario(scenario),
      ],
    );
  }

  List<Widget> _buildOutcomeCardsForScenario(SimulationScenario scenario) {
    switch (scenario) {
      case SimulationScenario.normal:
        return [
          _buildOutcomeCard(
            icon: FontAwesomeIcons.check,
            iconColor: const Color(0xFF16A34A),
            iconBackgroundColor: const Color(0xFFDCFCE7),
            title: 'On-Time Compliance',
            description: 'Making payments on schedule maintains good standing and avoids penalties.',
            borderColor: const Color(0xFFDBEAFE),
            benefits: ['✓ No additional fees'],
            delay: 0,
          ),
        ];
        
      case SimulationScenario.missedPayment:
        return [
          _buildOutcomeCard(
            icon: FontAwesomeIcons.check,
            iconColor: const Color(0xFF16A34A),
            iconBackgroundColor: const Color(0xFFDCFCE7),
            title: 'On-Time Compliance',
            description: 'Making payments on schedule maintains good standing and avoids penalties.',
            borderColor: const Color(0xFFDBEAFE),
            benefits: ['✓ No additional fees'],
            delay: 0,
          ),
          const SizedBox(height: 12),
          _buildOutcomeCard(
            icon: FontAwesomeIcons.exclamation,
            iconColor: const Color(0xFFF59E0B),
            iconBackgroundColor: const Color(0xFFFFF4E5),
            title: 'Late Payment Scenario',
            description: 'Missing the payment deadline triggers a 15-day grace period with accumulating fees.',
            borderColor: const Color(0xFFFED7AA),
            benefits: ['⚠ \$150 late fee + 2% monthly interest'],
            delay: 200,
          ),
        ];
        
      case SimulationScenario.earlyTermination:
        return [
          _buildOutcomeCard(
            icon: FontAwesomeIcons.check,
            iconColor: const Color(0xFF16A34A),
            iconBackgroundColor: const Color(0xFFDCFCE7),
            title: 'On-Time Compliance',
            description: 'Making payments on schedule maintains good standing and avoids penalties.',
            borderColor: const Color(0xFFDBEAFE),
            benefits: ['✓ No additional fees'],
            delay: 0,
          ),
          const SizedBox(height: 12),
          _buildOutcomeCard(
            icon: FontAwesomeIcons.exclamation,
            iconColor: const Color(0xFFF59E0B),
            iconBackgroundColor: const Color(0xFFFFF4E5),
            title: 'Late Payment Scenario',
            description: 'Missing the payment deadline triggers a 15-day grace period with accumulating fees.',
            borderColor: const Color(0xFFFED7AA),
            benefits: ['⚠ \$150 late fee + 2% monthly interest'],
            delay: 200,
          ),
          const SizedBox(height: 12),
          _buildOutcomeCard(
            icon: FontAwesomeIcons.triangleExclamation,
            iconColor: const Color(0xFFEF4444),
            iconBackgroundColor: const Color(0xFFFEE2E2),
            title: 'Contract Breach',
            description: 'Failure to remedy payment issues within 30 days may result in contract termination and legal action.',
            borderColor: const Color(0xFFFECACA),
            benefits: [
              '🚨 Immediate termination clause activated',
              '⚖️ Legal fees: \$5,000-\$15,000',
            ],
            delay: 400,
            isHighRisk: true,
          ),
        ];
    }
  }

  Widget _buildOutcomeCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required String title,
    required String description,
    required Color borderColor,
    required List<String> benefits,
    required int delay,
    bool isHighRisk = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 16,
              ),
            )
                .animate(delay: delay.ms)
                .scale(
                  begin: const Offset(0.5, 0.5),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 600.ms),
            
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
                      fontWeight: FontWeight.w600,
                      color: isHighRisk ? iconColor : const Color(0xFF1F2937),
                    ),
                  )
                      .animate(delay: (delay + 100).ms)
                      .slideX(
                        begin: 0.3,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(duration: 500.ms),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  )
                      .animate(delay: (delay + 200).ms)
                      .slideX(
                        begin: 0.3,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(duration: 500.ms),
                  
                  const SizedBox(height: 8),
                  
                  // Benefits
                  ...benefits.asMap().entries.map((entry) {
                    final index = entry.key;
                    final benefit = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        benefit,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: iconColor,
                        ),
                      )
                          .animate(delay: (delay + 300 + (index * 100)).ms)
                          .slideX(
                            begin: 0.3,
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          )
                          .fadeIn(duration: 400.ms),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
