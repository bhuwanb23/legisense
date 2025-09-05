import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../components/main_header.dart';

class SimulationPage extends StatelessWidget {
  const SimulationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Global Main Header
              const MainHeader(title: 'Simulation'),

              // Page body padding (keeps header flush)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    Text(
                      'Practice with sample legal scenarios',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    )
                        .animate()
                        .slideX(
                          begin: -0.3,
                          duration: 600.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: 800.ms, delay: 200.ms),
              
              const SizedBox(height: 32),
              
                  // Simulation Cards
                  _buildSimulationCard(
                title: 'Contract Analysis',
                subtitle: 'Learn to identify key terms and clauses',
                icon: FontAwesomeIcons.fileContract,
                color: const Color(0xFF3B82F6),
                progress: 0.7,
                delay: 400,
              ),
              
                  const SizedBox(height: 16),
              
                  _buildSimulationCard(
                title: 'Legal Research',
                subtitle: 'Practice finding relevant case law',
                icon: FontAwesomeIcons.magnifyingGlass,
                color: const Color(0xFF10B981),
                progress: 0.4,
                delay: 600,
              ),
              
                  const SizedBox(height: 16),
              
                  _buildSimulationCard(
                title: 'Document Drafting',
                subtitle: 'Create professional legal documents',
                icon: FontAwesomeIcons.penToSquare,
                color: const Color(0xFFF59E0B),
                progress: 0.2,
                delay: 800,
              ),
              
                  const SizedBox(height: 32),
              
                  // Quick Start Button
                  Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Starting a new simulation...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.play,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Start New Simulation',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 800.ms, delay: 1000.ms),
                  const SizedBox(height: 24),
                ],
              ),
              // End Padding
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideX(
          begin: 0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 800.ms, delay: delay.ms);
  }
}
