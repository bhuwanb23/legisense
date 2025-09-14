import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'simulation_scenario.dart';

class TimelineView extends StatefulWidget {
  final SimulationScenario scenario;
  final String documentTitle;
  final Map<String, dynamic>? simulationData;
  
  const TimelineView({
    super.key,
    required this.scenario,
    required this.documentTitle,
    this.simulationData,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final Set<int> _expandedNodes = {};

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
                    FontAwesomeIcons.sitemap,
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
                        'Interactive Timeline',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        '${widget.documentTitle} - AI Generated Flow',
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
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        FontAwesomeIcons.robot,
                        size: 12,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI Generated',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Interactive Timeline
            _buildInteractiveTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveTimeline() {
    final timelineData = _getTimelineData();
    
    return Column(
      children: timelineData.asMap().entries.map((entry) {
        final index = entry.key;
        final node = entry.value;
        final isLast = index == timelineData.length - 1;
        
        return Column(
          children: [
            _buildTimelineNode(
              node: node,
              index: index,
              isExpanded: _expandedNodes.contains(index),
              onTap: () => _toggleNode(index),
            ),
            if (!isLast) _buildConnectionLine(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTimelineNode({
    required TimelineNode node,
    required int index,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: node.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: node.borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: node.borderColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Node Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: node.iconColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      node.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Node Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          node.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Expand/Collapse Icon
                  Icon(
                    isExpanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
                    color: const Color(0xFF6B7280),
                    size: 16,
                  ),
                ],
              ),
              
              // Expanded Content
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                        'Detailed Analysis',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        node.detailedDescription,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF4B5563),
                          height: 1.5,
                        ),
                      ),
                      if (node.risks.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Potential Risks:',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...node.risks.map((risk) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              const Icon(
                                FontAwesomeIcons.triangleExclamation,
                                size: 10,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  risk,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate(delay: (index * 200).ms)
        .slideX(
          begin: -0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 600.ms);
  }

  Widget _buildConnectionLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          width: 2,
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2563EB).withValues(alpha: 0.3),
                const Color(0xFF2563EB).withValues(alpha: 0.8),
                const Color(0xFF2563EB).withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  void _toggleNode(int index) {
    setState(() {
      if (_expandedNodes.contains(index)) {
        _expandedNodes.remove(index);
      } else {
        _expandedNodes.add(index);
      }
    });
  }

  List<TimelineNode> _getTimelineData() {
    // Use real simulation data if available, otherwise fall back to mock data
    if (widget.simulationData != null) {
      final timelineData = widget.simulationData!['timeline'] as List<dynamic>?;
      if (timelineData != null && timelineData.isNotEmpty) {
        return timelineData.map((item) {
          final data = item as Map<String, dynamic>;
          return TimelineNode(
            title: data['title'] as String? ?? 'Timeline Event',
            description: data['description'] as String? ?? 'Event description',
            detailedDescription: data['detailed_description'] as String? ?? 'Detailed analysis of this timeline event.',
            icon: _getIconForOrder(data['order'] as int? ?? 0),
            iconColor: _getIconColorForOrder(data['order'] as int? ?? 0),
            backgroundColor: _getBackgroundColorForOrder(data['order'] as int? ?? 0),
            borderColor: _getBorderColorForOrder(data['order'] as int? ?? 0),
            risks: (data['risks'] as List<dynamic>?)?.cast<String>() ?? [],
          );
        }).toList();
      }
    }
    
    // Fall back to mock data based on scenario
    return _getTimelineDataForScenario(widget.scenario);
  }

  IconData _getIconForOrder(int order) {
    switch (order) {
      case 1:
        return FontAwesomeIcons.penToSquare;
      case 2:
        return FontAwesomeIcons.dollarSign;
      case 3:
        return FontAwesomeIcons.clock;
      case 4:
        return FontAwesomeIcons.triangleExclamation;
      case 5:
        return FontAwesomeIcons.gavel;
      default:
        return FontAwesomeIcons.circleCheck;
    }
  }

  Color _getIconColorForOrder(int order) {
    switch (order) {
      case 1:
        return const Color(0xFF2563EB);
      case 2:
        return const Color(0xFF10B981);
      case 3:
        return const Color(0xFFF59E0B);
      case 4:
        return const Color(0xFFEF4444);
      case 5:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _getBackgroundColorForOrder(int order) {
    switch (order) {
      case 1:
        return const Color(0xFFEFF6FF);
      case 2:
        return const Color(0xFFECFDF5);
      case 3:
        return const Color(0xFFFFF7ED);
      case 4:
        return const Color(0xFFFEF2F2);
      case 5:
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFECFDF5);
    }
  }

  Color _getBorderColorForOrder(int order) {
    switch (order) {
      case 1:
        return const Color(0xFF2563EB);
      case 2:
        return const Color(0xFF10B981);
      case 3:
        return const Color(0xFFF59E0B);
      case 4:
        return const Color(0xFFEF4444);
      case 5:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10B981);
    }
  }

  List<TimelineNode> _getTimelineDataForScenario(SimulationScenario scenario) {
    switch (scenario) {
      case SimulationScenario.normal:
        return [
          TimelineNode(
            title: 'Contract Signing',
            description: 'Initial obligations and terms established',
            detailedDescription: 'Upon signing, both parties agree to the terms outlined in the contract. This includes payment schedules, deliverables, and compliance requirements.',
            icon: FontAwesomeIcons.penToSquare,
            iconColor: const Color(0xFF2563EB),
            backgroundColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFF2563EB),
            risks: [],
          ),
          TimelineNode(
            title: 'Payment Due',
            description: 'Monthly payment of \$2,500 required',
            detailedDescription: 'Payment is due on the 1st of each month. Late payments incur a \$150 fee plus 2% monthly interest.',
            icon: FontAwesomeIcons.dollarSign,
            iconColor: const Color(0xFF10B981),
            backgroundColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFF10B981),
            risks: ['Late payment fees apply after 15 days'],
          ),
          TimelineNode(
            title: 'Compliance Check',
            description: 'Regular monitoring of contract adherence',
            detailedDescription: 'Monthly review of all contract terms to ensure both parties are meeting their obligations.',
            icon: FontAwesomeIcons.circleCheck,
            iconColor: const Color(0xFF10B981),
            backgroundColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFF10B981),
            risks: [],
          ),
        ];
        
      case SimulationScenario.missedPayment:
        return [
          TimelineNode(
            title: 'Contract Signing',
            description: 'Initial obligations and terms established',
            detailedDescription: 'Upon signing, both parties agree to the terms outlined in the contract. This includes payment schedules, deliverables, and compliance requirements.',
            icon: FontAwesomeIcons.penToSquare,
            iconColor: const Color(0xFF2563EB),
            backgroundColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFF2563EB),
            risks: [],
          ),
          TimelineNode(
            title: 'Payment Missed',
            description: 'Payment deadline exceeded - Grace period activated',
            detailedDescription: 'Payment was not received by the due date. A 15-day grace period is now active with accumulating late fees.',
            icon: FontAwesomeIcons.clock,
            iconColor: const Color(0xFFF59E0B),
            backgroundColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFF59E0B),
            risks: ['\$150 late fee applied', '2% monthly interest accumulating'],
          ),
          TimelineNode(
            title: 'Default Notice',
            description: 'Formal notice of contract breach',
            detailedDescription: 'After 30 days of non-payment, a formal default notice is issued. This triggers additional penalties and potential legal action.',
            icon: FontAwesomeIcons.triangleExclamation,
            iconColor: const Color(0xFFEF4444),
            backgroundColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFEF4444),
            risks: ['Legal action may be initiated', 'Additional \$500 penalty fee'],
          ),
        ];
        
      case SimulationScenario.earlyTermination:
        return [
          TimelineNode(
            title: 'Contract Signing',
            description: 'Initial obligations and terms established',
            detailedDescription: 'Upon signing, both parties agree to the terms outlined in the contract. This includes payment schedules, deliverables, and compliance requirements.',
            icon: FontAwesomeIcons.penToSquare,
            iconColor: const Color(0xFF2563EB),
            backgroundColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFF2563EB),
            risks: [],
          ),
          TimelineNode(
            title: 'Early Termination Request',
            description: 'Request to terminate contract before completion',
            detailedDescription: 'One party requests early termination. This triggers review of termination clauses and penalty calculations.',
            icon: FontAwesomeIcons.fileContract,
            iconColor: const Color(0xFFF59E0B),
            backgroundColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFF59E0B),
            risks: ['Early termination fees apply', 'Remaining contract value due'],
          ),
          TimelineNode(
            title: 'Legal Action',
            description: 'Contract breach leads to legal proceedings',
            detailedDescription: 'Failure to resolve termination terms results in legal action. This includes court costs, legal fees, and potential damages.',
            icon: FontAwesomeIcons.gavel,
            iconColor: const Color(0xFFEF4444),
            backgroundColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFEF4444),
            risks: ['Legal fees: \$5,000-\$15,000', 'Court costs and damages', 'Credit impact'],
          ),
        ];
    }
  }
}

class TimelineNode {
  final String title;
  final String description;
  final String detailedDescription;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final List<String> risks;

  TimelineNode({
    required this.title,
    required this.description,
    required this.detailedDescription,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.risks,
  });
}
