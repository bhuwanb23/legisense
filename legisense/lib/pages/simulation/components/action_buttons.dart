import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback? onRunSimulation;
  final VoidCallback? onExportReport;
  
  const ActionButtons({
    super.key,
    this.onRunSimulation,
    this.onExportReport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Run Simulation Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onRunSimulation ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulation started!'),
                  backgroundColor: Color(0xFF2563EB),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FontAwesomeIcons.play,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Run Simulation',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .slideY(
              begin: 0.3,
              duration: 600.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(duration: 600.ms),
        
        const SizedBox(height: 12),
        
        // Export Report Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onExportReport ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report exported successfully!'),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(
                color: Color(0xFF2563EB),
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FontAwesomeIcons.download,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Export Report',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate(delay: 200.ms)
            .slideY(
              begin: 0.3,
              duration: 600.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(duration: 600.ms),
      ],
    );
  }
}
