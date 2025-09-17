import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'styles.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

class NextStepsCTA extends StatelessWidget {
  final VoidCallback? onBackToAnalysis;
  final VoidCallback? onSaveSimulation;
  final VoidCallback? onExportReport;
  final VoidCallback? onShareResults;
  final String documentTitle;
  
  const NextStepsCTA({
    super.key,
    this.onBackToAnalysis,
    this.onSaveSimulation,
    this.onExportReport,
    this.onShareResults,
    required this.documentTitle,
  });

  @override
  Widget build(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
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
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(SimStyles.radiusM),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.arrowRight,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SimStyles.spaceS),
                Text(
                  i18n['next.title'] ?? 'Next Steps',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  i18n['next.subtitle'] ?? 'Choose your next action',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: SimStyles.spaceL),
            
            // Action Buttons Grid
            Column(
              children: [
                // Primary Actions Row
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: FontAwesomeIcons.arrowLeft,
                        title: i18n['next.back'] ?? 'Back to Analysis',
                        subtitle: i18n['next.back.subtitle'] ?? 'Return to clause breakdown',
                        color: const Color(0xFF6B7280),
                        onTap: onBackToAnalysis ?? () {
                          Navigator.of(context).pop();
                        },
                        delay: 0,
                      ),
                    ),
                    const SizedBox(width: SimStyles.spaceS),
                    Expanded(
                      child: _buildActionButton(
                        icon: FontAwesomeIcons.floppyDisk,
                        title: i18n['next.save'] ?? 'Save Simulation',
                        subtitle: i18n['next.save.subtitle'] ?? 'Store in profile',
                        color: const Color(0xFF2563EB),
                        onTap: onSaveSimulation ?? () {
                          _showSaveDialog(context);
                        },
                        delay: 100,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: SimStyles.spaceS),
                
                // Secondary Actions Row
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: FontAwesomeIcons.download,
                        title: i18n['next.export'] ?? 'Export Report',
                        subtitle: i18n['next.export.subtitle'] ?? 'Download PDF',
                        color: const Color(0xFF10B981),
                        onTap: onExportReport ?? () {
                          _showExportDialog(context);
                        },
                        delay: 200,
                      ),
                    ),
                    const SizedBox(width: SimStyles.spaceS),
                    Expanded(
                      child: _buildActionButton(
                        icon: FontAwesomeIcons.share,
                        title: i18n['next.share'] ?? 'Share Results',
                        subtitle: i18n['next.share.subtitle'] ?? 'Send to team',
                        color: const Color(0xFF8B5CF6),
                        onTap: onShareResults ?? () {
                          _showShareDialog(context);
                        },
                        delay: 300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: SimStyles.spaceL),
            
            // Quick Stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SimStyles.spaceM),
              decoration: SimStyles.insetCard(
                color: const Color(0xFFF0F9FF),
                borderColor: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.chartLine,
                        size: 14,
                        color: const Color(0xFF0EA5E9),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        i18n['next.summary.title'] ?? 'Simulation Summary',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0EA5E9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          label: i18n['next.summary.scenarios'] ?? 'Scenarios Tested',
                          value: '3',
                          icon: FontAwesomeIcons.play,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          label: i18n['next.summary.alerts'] ?? 'Risk Alerts',
                          value: '2',
                          icon: FontAwesomeIcons.shield,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          label: i18n['next.summary.outcomes'] ?? 'Outcomes',
                          value: '5',
                          icon: FontAwesomeIcons.lightbulb,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SimStyles.spaceM),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(SimStyles.radiusM),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
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
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    )
        .animate(delay: delay.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          duration: 400.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 400.ms);
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFF0EA5E9),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0EA5E9),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Simulation'),
        content: Text('Save simulation results for "$documentTitle" to your profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Simulation saved for $documentTitle'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: const Text('Export simulation report as PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Report exported for $documentTitle'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Results'),
        content: const Text('Share simulation results with your team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Results shared for $documentTitle'),
                  backgroundColor: const Color(0xFF8B5CF6),
                ),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
