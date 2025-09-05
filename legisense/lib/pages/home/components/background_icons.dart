import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BackgroundIcons extends StatelessWidget {
  const BackgroundIcons({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scale Balanced Icon - Top Left
        Positioned(
          top: 80,
          left: 32,
          child: _buildFloatingIcon(
            icon: FontAwesomeIcons.scaleBalanced,
            size: 48,
            delay: 0,
          ),
        ),
        
        // Scroll Icon - Top Right
        Positioned(
          top: 160,
          right: 48,
          child: _buildFloatingIcon(
            icon: FontAwesomeIcons.scroll,
            size: 40,
            delay: 2000,
          ),
        ),
        
        // Compass Icon - Bottom Left
        Positioned(
          bottom: 128,
          left: 24,
          child: _buildFloatingIcon(
            icon: FontAwesomeIcons.compass,
            size: 32,
            delay: 4000,
          ),
        ),
        
        // Gavel Icon - Top Center
        Positioned(
          top: 240,
          left: MediaQuery.of(context).size.width / 2 - 20,
          child: _buildFloatingIcon(
            icon: FontAwesomeIcons.gavel,
            size: 40,
            delay: 1000,
          ),
        ),
        
        // Book Open Icon - Bottom Right
        Positioned(
          bottom: 80,
          right: 32,
          child: _buildFloatingIcon(
            icon: FontAwesomeIcons.bookOpen,
            size: 32,
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
    return Container(
      width: size,
      height: size,
      child: Icon(
        icon,
        color: const Color(0xFF1E40AF).withValues(alpha: 0.03),
        size: size,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .moveY(
          begin: 0,
          end: -10,
          duration: 6000.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .moveY(
          begin: -10,
          end: 0,
          duration: 6000.ms,
          curve: Curves.easeInOut,
        )
        .fadeIn(duration: 1000.ms, delay: delay.ms);
  }
}
