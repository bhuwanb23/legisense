import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecentFiles extends StatelessWidget {
  const RecentFiles({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> recentFiles = [
      {
        'title': 'Employment Contract.pdf',
        'subtitle': 'Uploaded 2 hours ago',
        'icon': FontAwesomeIcons.filePdf,
        'color': const Color(0xFFEF4444),
        'bgColor': const Color(0xFFFEE2E2),
      },
      {
        'title': 'Service Agreement.docx',
        'subtitle': 'Uploaded yesterday',
        'icon': FontAwesomeIcons.fileWord,
        'color': const Color(0xFF2563EB),
        'bgColor': const Color(0xFFDBEAFE),
      },
      {
        'title': 'NDA Template.pdf',
        'subtitle': 'Uploaded 3 days ago',
        'icon': FontAwesomeIcons.filePdf,
        'color': const Color(0xFF10B981),
        'bgColor': const Color(0xFFDCFCE7),
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Files',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          )
              .animate()
              .slideY(
                begin: 0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 800.ms, delay: 200.ms),
          
          const SizedBox(height: 16),
          
          ...recentFiles.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> file = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFileCard(
                title: file['title'],
                subtitle: file['subtitle'],
                icon: file['icon'],
                color: file['color'],
                bgColor: file['bgColor'],
                delay: 400 + (index * 200),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFileCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required int delay,
  }) {
    return Container(
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // File Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // File Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
          
          // More Options Button
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Builder(
              builder: (context) => IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Options for "$title"'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(
                FontAwesomeIcons.ellipsisVertical,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
              padding: EdgeInsets.zero,
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
