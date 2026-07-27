import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'simulation_scenario.dart';
import 'styles.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

class NarrativeOutcomeCards extends StatelessWidget {
  final SimulationScenario scenario;
  final Map<String, dynamic>? parameters;
  final Map<String, dynamic>? simulationData;
  
  const NarrativeOutcomeCards({
    super.key,
    required this.scenario,
    this.parameters,
    this.simulationData,
  });

  @override
  Widget build(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
    final outcomes = _getNarrativeOutcomes(simulationData, scenario, parameters);
    
    return Container(
      decoration: SimStyles.sectionDecoration(),
      child: Padding(
        padding: SimStyles.sectionPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(SimStyles.spaceS),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(SimStyles.radiusM),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.bookOpen,
                        color: Color(0xFF8B5CF6),
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: SimStyles.badgeDecoration(const Color(0xFF8B5CF6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            FontAwesomeIcons.wandMagic,
                            size: 11,
                            color: Color(0xFF8B5CF6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            i18n['narrative.mode'] ?? 'Storytelling Mode',
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
                const SizedBox(height: SimStyles.spaceS),
                Text(
                  i18n['narrative.title'] ?? 'Narrative Outcomes',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  i18n['narrative.subtitle'] ?? 'Plain-English scenario explanations',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: SimStyles.spaceL),
            
            // Narrative Cards
            ...outcomes.asMap().entries.map((entry) {
              final index = entry.key;
              final outcome = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < outcomes.length - 1 ? 16 : 0),
                child: _buildNarrativeCard(outcome, index, i18n),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrativeCard(NarrativeOutcome outcome, int index, Map<String, String> i18n) {
    return Container(
      decoration: BoxDecoration(
        color: outcome.backgroundColor,
        borderRadius: BorderRadius.circular(SimStyles.radiusM),
        border: Border.all(
          color: outcome.borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SimStyles.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: outcome.iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    outcome.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: SimStyles.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outcome.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        outcome.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: outcome.severityColor,
                    borderRadius: BorderRadius.circular(SimStyles.radiusS),
                  ),
                  child: Text(
                    outcome.severityText,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: SimStyles.spaceM),
            
            // Narrative Story
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SimStyles.spaceS),
              decoration: SimStyles.insetCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.quoteLeft,
                        size: 14,
                        color: outcome.iconColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        i18n['narrative.story'] ?? 'Scenario Story',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    outcome.narrative,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF4B5563),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: SimStyles.spaceM),
            
            // Key Points
            if (outcome.keyPoints.isNotEmpty) ...[
              Text(
                i18n['narrative.keypoints'] ?? 'Key Points:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              ...outcome.keyPoints.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: outcome.iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            
            const SizedBox(height: SimStyles.spaceM),
            
            // Financial Impact
            if (outcome.financialImpact.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SimStyles.spaceS),
                decoration: SimStyles.insetCard(
                  color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
                  borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.dollarSign,
                          size: 14,
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          i18n['narrative.financial'] ?? 'Financial Impact',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...outcome.financialImpact.map((impact) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        impact,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    )
        .animate(delay: (index * 200).ms)
        .slideY(
          begin: 0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 600.ms);
  }

  List<NarrativeOutcome> _getNarrativeOutcomes(Map<String, dynamic>? simulationData, SimulationScenario scenario, Map<String, dynamic>? parameters) {
    // Use real simulation data if available, otherwise fall back to scenario-based data
    if (simulationData != null) {
      final narrativesData = simulationData['narratives'] as List<dynamic>?;
      if (narrativesData != null && narrativesData.isNotEmpty) {
        return narrativesData.map((item) {
          final data = item as Map<String, dynamic>;
          return NarrativeOutcome(
            title: data['title'] as String? ?? 'Narrative Outcome',
            subtitle: data['subtitle'] as String? ?? 'Outcome description',
            narrative: data['narrative'] as String? ?? 'Detailed narrative description.',
            icon: _getIconForSeverity(data['severity'] as String? ?? 'low'),
            iconColor: _getColorForSeverity(data['severity'] as String? ?? 'low'),
            backgroundColor: _getBackgroundColorForSeverity(data['severity'] as String? ?? 'low'),
            borderColor: _getBorderColorForSeverity(data['severity'] as String? ?? 'low'),
            severityText: _getSeverityText(data['severity'] as String? ?? 'low'),
            severityColor: _getColorForSeverity(data['severity'] as String? ?? 'low'),
            keyPoints: (data['key_points'] as List<dynamic>?)?.cast<String>() ?? [],
            financialImpact: (data['financial_impact'] as List<dynamic>?)?.cast<String>() ?? [],
          );
        }).toList();
      }
    }
    
    // Fall back to scenario-based data if no simulation data available
    return _getNarrativeOutcomesForScenario(scenario, parameters);
  }

  List<NarrativeOutcome> _getNarrativeOutcomesForScenario(SimulationScenario scenario, Map<String, dynamic>? parameters) {
    final missedPayments = parameters?['missedPayments'] ?? 0;
    final interestRate = parameters?['interestRate'] ?? 2.0;
    final delayDays = parameters?['delayDays'] ?? 0;
    
    switch (scenario) {
      case SimulationScenario.normal:
        return [
          NarrativeOutcome(
            title: 'Smooth Contract Execution',
            subtitle: 'Everything goes according to plan',
            narrative: 'In this ideal scenario, both parties fulfill their obligations perfectly. Payments are made on time, services are delivered as promised, and the contract proceeds smoothly from start to finish. This represents the best-case outcome where all terms are met without any complications.',
            icon: FontAwesomeIcons.circleCheck,
            iconColor: const Color(0xFF10B981),
            backgroundColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFF10B981),
            severityText: 'LOW RISK',
            severityColor: const Color(0xFF10B981),
            keyPoints: [
              'All payments made on schedule',
              'No additional fees or penalties',
              'Contract terms fully satisfied',
              'Positive relationship maintained',
            ],
            financialImpact: [
              'Total cost: \$30,000 (as agreed)',
              'No additional fees',
              'No interest charges',
            ],
          ),
        ];
        
      case SimulationScenario.missedPayment:
        return [
          NarrativeOutcome(
            title: 'Payment Delay Scenario',
            subtitle: 'What happens when payments are missed',
            narrative: 'When ${missedPayments > 0 ? '$missedPayments payment${missedPayments > 1 ? 's are' : ' is'} missed' : 'payments are delayed'}, the contract enters a penalty phase. The lender applies late fees and interest charges, creating a compounding financial burden. ${missedPayments > 2 ? 'After multiple missed payments, the situation escalates to formal default proceedings.' : 'If payments continue to be missed, the situation could escalate further.'}',
            icon: FontAwesomeIcons.clock,
            iconColor: const Color(0xFFF59E0B),
            backgroundColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFF59E0B),
            severityText: 'MEDIUM RISK',
            severityColor: const Color(0xFFF59E0B),
            keyPoints: [
              missedPayments > 0 ? '$missedPayments payment${missedPayments > 1 ? 's' : ''} missed' : 'Payment delays occur',
              'Late fees: \$150 per missed payment',
              'Interest rate: $interestRate% monthly',
              'Grace period: 15 days per payment',
            ],
            financialImpact: [
              'Late fees: \$${150 * missedPayments}',
              'Interest charges: $interestRate% monthly',
              'Total additional cost: \$${(150 * missedPayments) + (30000 * interestRate / 100 * missedPayments).round()}',
            ],
          ),
          if (missedPayments > 2)
            NarrativeOutcome(
              title: 'Default Notice Issued',
              subtitle: 'Contract breach proceedings initiated',
              narrative: 'After $missedPayments missed payments, the lender has no choice but to issue a formal default notice. This marks a serious escalation in the contract dispute. The borrower now faces immediate payment demands, additional penalties, and potential legal action. This scenario represents a significant breakdown in the contractual relationship.',
              icon: FontAwesomeIcons.triangleExclamation,
              iconColor: const Color(0xFFEF4444),
              backgroundColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFEF4444),
              severityText: 'HIGH RISK',
              severityColor: const Color(0xFFEF4444),
              keyPoints: [
                'Formal default notice issued',
                'Additional \$500 penalty fee',
                'Legal action may be initiated',
                'Credit score impact',
              ],
              financialImpact: [
                'Default penalty: \$500',
                'Legal fees: \$2,000-\$5,000',
                'Total additional cost: \$${500 + (150 * missedPayments) + (30000 * interestRate / 100 * missedPayments).round()}',
              ],
            ),
        ];
        
      case SimulationScenario.earlyTermination:
        return [
          NarrativeOutcome(
            title: 'Early Termination Request',
            subtitle: 'Breaking the contract before completion',
            narrative: 'When one party requests early termination, the contract enters a complex negotiation phase. The terminating party must pay all outstanding obligations plus early termination fees. This scenario often involves significant financial penalties and can strain the business relationship. ${delayDays > 0 ? 'With a $delayDays-day delay in the termination process, additional complications arise.' : ''}',
            icon: FontAwesomeIcons.fileContract,
            iconColor: const Color(0xFFF59E0B),
            backgroundColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFF59E0B),
            severityText: 'HIGH RISK',
            severityColor: const Color(0xFFF59E0B),
            keyPoints: [
              'Early termination requested',
              'Remaining contract value due',
              'Early termination fees apply',
              delayDays > 0 ? '$delayDays-day delay in process' : 'Immediate processing',
            ],
            financialImpact: [
              'Remaining contract value: \$15,000',
              'Early termination fee: \$5,000',
              delayDays > 0 ? 'Delay penalty: \$${delayDays * 50}' : 'No delay penalty',
            ],
          ),
          NarrativeOutcome(
            title: 'Legal Action Initiated',
            subtitle: 'Contract dispute escalates to court',
            narrative: 'When early termination terms cannot be agreed upon, the dispute escalates to legal proceedings. This represents the worst-case scenario where both parties incur significant legal costs and the relationship is permanently damaged. The court will determine the final settlement, which may include additional damages beyond the original contract terms.',
            icon: FontAwesomeIcons.gavel,
            iconColor: const Color(0xFFEF4444),
            backgroundColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFEF4444),
            severityText: 'CRITICAL RISK',
            severityColor: const Color(0xFFEF4444),
            keyPoints: [
              'Legal proceedings initiated',
              'Court costs and legal fees',
              'Potential additional damages',
              'Credit score impact',
            ],
            financialImpact: [
              'Legal fees: \$5,000-\$15,000',
              'Court costs: \$2,000-\$5,000',
              'Potential damages: \$10,000-\$25,000',
              'Total potential cost: \$17,000-\$45,000',
            ],
          ),
        ];
    }
  }

  IconData _getIconForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return FontAwesomeIcons.triangleExclamation;
      case 'high':
        return FontAwesomeIcons.circleExclamation;
      case 'medium':
        return FontAwesomeIcons.circleInfo;
      case 'low':
      default:
        return FontAwesomeIcons.circleCheck;
    }
  }

  Color _getColorForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626); // red-600
      case 'high':
        return const Color(0xFFEA580C); // orange-600
      case 'medium':
        return const Color(0xFFD97706); // amber-600
      case 'low':
      default:
        return const Color(0xFF10B981); // emerald-500
    }
  }

  Color _getBackgroundColorForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFEF2F2); // red-50
      case 'high':
        return const Color(0xFFFFF7ED); // orange-50
      case 'medium':
        return const Color(0xFFFFFBEB); // amber-50
      case 'low':
      default:
        return const Color(0xFFECFDF5); // emerald-50
    }
  }

  Color _getBorderColorForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626); // red-600
      case 'high':
        return const Color(0xFFEA580C); // orange-600
      case 'medium':
        return const Color(0xFFD97706); // amber-600
      case 'low':
      default:
        return const Color(0xFF10B981); // emerald-500
    }
  }

  String _getSeverityText(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 'CRITICAL RISK';
      case 'high':
        return 'HIGH RISK';
      case 'medium':
        return 'MEDIUM RISK';
      case 'low':
      default:
        return 'LOW RISK';
    }
  }
}

class NarrativeOutcome {
  final String title;
  final String subtitle;
  final String narrative;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String severityText;
  final Color severityColor;
  final List<String> keyPoints;
  final List<String> financialImpact;

  NarrativeOutcome({
    required this.title,
    required this.subtitle,
    required this.narrative,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.severityText,
    required this.severityColor,
    required this.keyPoints,
    required this.financialImpact,
  });
}
