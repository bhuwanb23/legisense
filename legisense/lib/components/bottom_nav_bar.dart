import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveHelper.isSmallScreen(context);
    
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: isSmallScreen ? 65 : 75,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 2 : 4, 
              vertical: isSmallScreen ? 4 : 6,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final itemWidth = availableWidth / 4;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(
                      icon: FontAwesomeIcons.house,
                      label: 'Home',
                      index: 0,
                      isActive: currentIndex == 0,
                      isSmallScreen: isSmallScreen,
                      width: itemWidth,
                    ),
                    _buildNavItem(
                      icon: FontAwesomeIcons.fileLines,
                      label: 'Documents',
                      index: 1,
                      isActive: currentIndex == 1,
                      isSmallScreen: isSmallScreen,
                      width: itemWidth,
                    ),
                    _buildNavItem(
                      icon: FontAwesomeIcons.play,
                      label: 'Simulation',
                      index: 2,
                      isActive: currentIndex == 2,
                      isSmallScreen: isSmallScreen,
                      width: itemWidth,
                    ),
                    _buildNavItem(
                      icon: FontAwesomeIcons.user,
                      label: 'Profile',
                      index: 3,
                      isActive: currentIndex == 3,
                      isSmallScreen: isSmallScreen,
                      width: itemWidth,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required bool isSmallScreen,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 2 : 4, 
              vertical: isSmallScreen ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: isActive 
                  ? const Color(0xFF2563EB)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: isSmallScreen ? 14 : 16,
                  color: isActive 
                      ? Colors.white
                      : const Color(0xFF2563EB),
                ),
                
                SizedBox(height: isSmallScreen ? 1 : 2),
                
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 8 : 9,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive 
                        ? Colors.white
                        : const Color(0xFF2563EB),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
