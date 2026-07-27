import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../utils/responsive.dart';

class BackgroundIcons extends StatelessWidget {
  const BackgroundIcons({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = ResponsiveHelper.isSmallScreen(context);
    final isLarge = ResponsiveHelper.isLargeScreen(context);

    // Base sizes adjusted by screen
    final double base = isSmall ? 24 : (isLarge ? 40 : 32);
    final double gap = isSmall ? 10 : 20;

    return Stack(
      children: [
        // Scale Balanced Icon - Top Left
        Positioned(
          top: gap * 3.5,
          left: gap * 1.5,
          child: _buildFloatingIcon(
            icon: FontAwesomeIcons.scaleBalanced,
            size: base + 8,
            delay: 0,
          ),
        ),
        
        // Scroll Icon - Top Right
        Positioned(
          top: gap * 6,
          right: gap * 2,
          child: _buildFloatingIcon(
            icon: FontAwesomeIcons.scroll,
            size: base,
            delay: 2000,
          ),
        ),
        
        // Compass Icon - Bottom Left
        Positioned(
          bottom: gap * 5,
          left: gap * 1.2,
          child: _buildFloatingIcon(
            icon: FontAwesomeIcons.compass,
            size: base - 6,
            delay: 4000,
          ),
        ),
        
        // Gavel Icon - Top Center
        Positioned(
          top: gap * 8,
          left: width / 2 - (base / 2),
          child: _buildFloatingIcon(
            icon: FontAwesomeIcons.gavel,
            size: base,
            delay: 1000,
          ),
        ),
        
        // Book Open Icon - Bottom Right
        Positioned(
          bottom: gap * 3.5,
          right: gap * 1.5,
          child: _buildFloatingIcon(
            icon: FontAwesomeIcons.bookOpen,
            size: base - 6,
            delay: 3000,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingIcon({
    required IconData icon,
    required double size,
    required int delay,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        icon,
        color: const Color(0xFF1E40AF).withValues(alpha: 0.02),
        size: size,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .moveY(
          begin: 0,
          end: -6,
          duration: 6000.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .moveY(
          begin: -6,
          end: 0,
          duration: 6000.ms,
          curve: Curves.easeInOut,
        )
        .fadeIn(duration: 1000.ms, delay: delay.ms);
  }
}
