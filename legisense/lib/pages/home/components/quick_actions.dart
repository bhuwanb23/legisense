import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../utils/responsive.dart';
import '../../../main.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {
        'icon': FontAwesomeIcons.magnifyingGlass,
        'title': 'Analyze',
        'subtitle': 'Upload & analyze documents',
        'gradient': const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'delay': 200,
        'onTap': () => navigateToPage(1), // Navigate to Documents page
      },
      {
        'icon': FontAwesomeIcons.clockRotateLeft,
        'title': 'History',
        'subtitle': 'View past analyses',
        'gradient': const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'delay': 400,
        'onTap': () => navigateToPage(1), // Navigate to Documents page
      },
      {
        'icon': FontAwesomeIcons.play,
        'title': 'Simulate',
        'subtitle': 'Run scenarios',
        'gradient': const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'delay': 600,
        'onTap': () => navigateToPage(2), // Navigate to Simulation page
      },
      {
        'icon': FontAwesomeIcons.user,
        'title': 'Profile',
        'subtitle': 'Account settings',
        'gradient': const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'delay': 800,
        'onTap': () => navigateToPage(3), // Navigate to Profile page
      },
    ];

    final width = MediaQuery.of(context).size.width;
    final isSmall = ResponsiveHelper.isSmallScreen(context);
    final isLarge = ResponsiveHelper.isLargeScreen(context);
    final crossAxisCount = width >= 900
        ? 5
        : width >= 720
            ? 4
            : width >= 520
                ? 3
                : 2;
    final childAspect = isLarge
        ? 1.2
        : isSmall
            ? 1.05
            : 1.1;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsivePadding(
          context,
          small: 8,
          medium: 12,
          large: 16,
        ),
        vertical: ResponsiveHelper.getResponsivePadding(
          context,
          small: 8,
          medium: 12,
          large: 16,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          )
              .animate()
              .slideY(
                begin: 0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              ),
          
          SizedBox(height: isSmall ? 8 : 12),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspect + 0.05,
              crossAxisSpacing: isSmall ? 6 : 8,
              mainAxisSpacing: isSmall ? 6 : 8,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildActionCard(
                context,
                icon: action['icon'],
                title: action['title'],
                subtitle: action['subtitle'],
                gradient: action['gradient'],
                delay: action['delay'],
                onTap: action['onTap'],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required int delay,
    required VoidCallback onTap,
  }) {
    final isSmall = ResponsiveHelper.isSmallScreen(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 8 : 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isSmall ? 10 : 14),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            Container(
              width: isSmall ? 26 : 32,
              height: isSmall ? 26 : 32,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isSmall ? 12 : 14,
              ),
            ),
            
            SizedBox(height: isSmall ? 3 : 5),
            
            // Title
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: isSmall ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: isSmall ? 0 : 1),
            
            // Subtitle
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: isSmall ? 9 : 10.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
        );
  }
}
