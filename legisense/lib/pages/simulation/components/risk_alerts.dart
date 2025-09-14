import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'simulation_scenario.dart';

class RiskAlerts extends StatelessWidget {
  final SimulationScenario scenario;
  final String documentTitle;
  final Map<String, dynamic>? simulationData;

  const RiskAlerts({
    super.key,
    required this.scenario,
    required this.documentTitle,
    this.simulationData,
  });

  @override
  Widget build(BuildContext context) {
    final alerts = _getRiskAlertsForScenario(scenario);
    
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

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
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.shield,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Risk Alerts & Insights',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'AI-detected high-risk clauses in current scenario',
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
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${alerts.length} Alert${alerts.length > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Risk Alerts
            ...alerts.asMap().entries.map((entry) {
              final index = entry.key;
              final alert = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < alerts.length - 1 ? 16 : 0),
                child: _buildRiskAlert(alert, index),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAlert(RiskAlert alert, int index) {
    return Container(
      decoration: BoxDecoration(
        color: alert.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert.borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Risk Level Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: alert.levelColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        alert.levelIcon,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        alert.levelText,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Alert Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: alert.iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    alert.icon,
                    color: alert.iconColor,
                    size: 16,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Alert Title
            Text(
              alert.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Alert Description
            Text(
              alert.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
            
            if (alert.impact.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Potential Impact:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: alert.iconColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...alert.impact.map((impact) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            FontAwesomeIcons.arrowRight,
                            size: 10,
                            color: alert.iconColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              impact,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
            
            if (alert.recommendation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      FontAwesomeIcons.lightbulb,
                      size: 14,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommendation:',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.recommendation,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    )
        .animate(delay: (index * 200).ms)
        .slideX(
          begin: 0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 600.ms);
  }

  List<RiskAlert> _getRiskAlertsForScenario(SimulationScenario scenario) {
    switch (scenario) {
      case SimulationScenario.normal:
        return [
          RiskAlert(
            title: 'Standard Contract Terms',
            description: 'This contract follows standard industry practices with reasonable terms and conditions.',
            level: RiskLevel.low,
            levelText: 'LOW RISK',
            levelIcon: FontAwesomeIcons.check,
            levelColor: const Color(0xFF10B981),
            icon: FontAwesomeIcons.shield,
            iconColor: const Color(0xFF10B981),
            backgroundColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFF10B981),
            impact: [
              'No immediate financial penalties',
              'Standard compliance requirements',
              'Predictable payment schedule',
            ],
            recommendation: 'Continue with current contract terms. Monitor compliance regularly.',
          ),
        ];
        
      case SimulationScenario.missedPayment:
        return [
          RiskAlert(
            title: 'Accumulating Late Fees',
            description: 'The contract allows for unlimited late fees that can compound monthly, potentially creating significant financial burden.',
            level: RiskLevel.high,
            levelText: 'HIGH RISK',
            levelIcon: FontAwesomeIcons.triangleExclamation,
            levelColor: const Color(0xFFEF4444),
            icon: FontAwesomeIcons.dollarSign,
            iconColor: const Color(0xFFEF4444),
            backgroundColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFEF4444),
            impact: [
              'Monthly late fees: \$150 + 2% interest',
              'Fees compound if not paid promptly',
              'Potential credit score impact',
              'Legal action after 30 days',
            ],
            recommendation: 'Make payment immediately to stop fee accumulation. Consider negotiating payment plan if needed.',
          ),
          RiskAlert(
            title: 'Default Notice Clause',
            description: 'This clause allows the lender to send a default notice after just 30 days, which is shorter than industry standard.',
            level: RiskLevel.medium,
            levelText: 'MEDIUM RISK',
            levelIcon: FontAwesomeIcons.exclamation,
            levelColor: const Color(0xFFF59E0B),
            icon: FontAwesomeIcons.fileContract,
            iconColor: const Color(0xFFF59E0B),
            backgroundColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFF59E0B),
            impact: [
              'Formal default notice after 30 days',
              'Additional \$500 penalty fee',
              'Potential legal action initiation',
            ],
            recommendation: 'Contact lender immediately to discuss payment options and avoid default notice.',
          ),
        ];
        
      case SimulationScenario.earlyTermination:
        return [
          RiskAlert(
            title: 'Unlimited Termination Fees',
            description: 'This clause allows the lender to charge unlimited fees for early termination, which could exceed the remaining contract value.',
            level: RiskLevel.high,
            levelText: 'HIGH RISK',
            levelIcon: FontAwesomeIcons.triangleExclamation,
            levelColor: const Color(0xFFEF4444),
            icon: FontAwesomeIcons.gavel,
            iconColor: const Color(0xFFEF4444),
            backgroundColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFEF4444),
            impact: [
              'Unlimited early termination fees',
              'Legal fees: \$5,000-\$15,000',
              'Court costs and potential damages',
              'Credit score impact',
            ],
            recommendation: 'Negotiate termination terms before proceeding. Consider legal consultation.',
          ),
          RiskAlert(
            title: 'Asset Seizure Clause',
            description: 'The contract includes a clause that allows asset seizure in case of default, which is unusually aggressive.',
            level: RiskLevel.high,
            levelText: 'HIGH RISK',
            levelIcon: FontAwesomeIcons.triangleExclamation,
            levelColor: const Color(0xFFEF4444),
            icon: FontAwesomeIcons.handcuffs,
            iconColor: const Color(0xFFEF4444),
            backgroundColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFEF4444),
            impact: [
              'Potential asset seizure',
              'Immediate enforcement action',
              'Limited appeal options',
            ],
            recommendation: 'Review asset protection strategies. Consider legal representation immediately.',
          ),
        ];
    }
  }
}

enum RiskLevel {
  low,
  medium,
  high,
}

class RiskAlert {
  final String title;
  final String description;
  final RiskLevel level;
  final String levelText;
  final IconData levelIcon;
  final Color levelColor;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final List<String> impact;
  final String recommendation;

  RiskAlert({
    required this.title,
    required this.description,
    required this.level,
    required this.levelText,
    required this.levelIcon,
    required this.levelColor,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.impact,
    required this.recommendation,
  });
}
