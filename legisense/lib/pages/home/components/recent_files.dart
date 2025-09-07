import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS + 6, vertical: AppTheme.spacingS + 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Files',
            style: AppTheme.heading4,
          )
              .animate()
              .slideY(
                begin: 0.3,
                duration: AppTheme.animationMedium,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),
          
          const SizedBox(height: AppTheme.spacingS + 6),
          
          ...recentFiles.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> file = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS + 6),
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
      padding: const EdgeInsets.all(AppTheme.spacingS + 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.backgroundWhite.withValues(alpha: 0.2),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingM),
          
          // File Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          
          // More Options Button
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
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
                color: AppTheme.textTertiary,
                size: 14,
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
          duration: AppTheme.animationMedium,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: AppTheme.animationSlow, delay: delay.ms);
  }
}
