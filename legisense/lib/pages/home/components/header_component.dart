import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../utils/responsive.dart';

class HeaderComponent extends StatelessWidget {
  const HeaderComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmall = ResponsiveHelper.isSmallScreen(context);
    final isLarge = ResponsiveHelper.isLargeScreen(context);
    final double padH = ResponsiveHelper.getResponsivePadding(
      context,
      small: 12,
      medium: 16,
      large: 20,
    );
    final double padV = isSmall ? 16 : 20;
    final double box = isSmall ? 30 : 38; // avatar and bell size
    final double radius = isSmall ? 9 : 11;
    final double titleSize = isSmall ? 17 : (isLarge ? 21 : 19);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: Row(
        children: [
          // Logo and Title
          Row(
            children: [
              Container(
                width: box,
                height: box,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: box - 4,
                    height: box - 4,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        FontAwesomeIcons.scaleBalanced,
                        color: Colors.white,
                        size: 16,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: isSmall ? 10 : 12),
              Text(
                'Legisense',
                style: GoogleFonts.inter(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Notification Bell
          Container(
            width: box,
            height: box,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              FontAwesomeIcons.bell,
              color: Color(0xFF6B7280),
              size: 16,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 800.ms, delay: 400.ms),
          
          SizedBox(width: isSmall ? 12 : 16),
          
          // Profile Avatar
          Container(
            width: box,
            height: box,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(box / 2),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: isSmall ? 6 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular((box / 2) - 2),
              child: Image.network(
                'https://storage.googleapis.com/uxpilot-auth.appspot.com/avatars/avatar-3.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE5E7EB),
                    child: const Icon(
                      FontAwesomeIcons.user,
                      color: Color(0xFF9CA3AF),
                      size: 18,
                    ),
                  );
                },
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 800.ms, delay: 600.ms),
        ],
      ),
    );
  }
}
