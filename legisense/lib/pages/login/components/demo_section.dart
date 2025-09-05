import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DemoSection extends StatelessWidget {
  const DemoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
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
      child: Column(
        children: [
          // Demo header
          Column(
            children: [
              Text(
                'Try Before You Sign Up',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .slideY(
                    begin: 0.3,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 800.ms, delay: 1000.ms),
              
              const SizedBox(height: 4),
              
              Text(
                'Explore with sample contracts',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFDBEAFE), // blue-100
                ),
              )
                  .animate()
                  .slideY(
                    begin: 0.3,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 800.ms, delay: 1200.ms),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Try Demo Button
          GestureDetector(
            onTap: () {
              // TODO: Implement demo functionality
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2DD4BF), // teal-400
                    Color(0xFF60A5FA), // blue-400
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FontAwesomeIcons.circlePlay,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Try Demo',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.9, 0.9),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 800.ms, delay: 1400.ms),
          
          const SizedBox(height: 12),
          
          // Sample contract types
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildContractType(
                icon: FontAwesomeIcons.fileContract,
                label: 'Contracts',
                delay: 1600,
              ),
              _buildContractType(
                icon: FontAwesomeIcons.house,
                label: 'Leases',
                delay: 1800,
              ),
              _buildContractType(
                icon: FontAwesomeIcons.briefcase,
                label: 'Terms',
                delay: 2000,
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .slideY(
          begin: 0.3,
          duration: 800.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 1000.ms, delay: 1000.ms);
  }

  Widget _buildContractType({
    required IconData icon,
    required String label,
    required int delay,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.8, 0.8),
              duration: 400.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 600.ms, delay: delay.ms),
        
        const SizedBox(height: 4),
        
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFDBEAFE), // blue-100
          ),
        )
            .animate()
            .slideY(
              begin: 0.3,
              duration: 400.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(duration: 600.ms, delay: (delay + 200).ms),
      ],
    );
  }
}
