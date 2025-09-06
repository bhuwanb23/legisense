import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/responsive.dart';

class MainHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBellPressed;

  const MainHeader({
    super.key,
    required this.title,
    this.onBellPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveHelper.isSmallScreen(context);
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : (isLargeScreen ? 32 : 24), 
        16, 
        isSmallScreen ? 16 : (isLargeScreen ? 32 : 24), 
        12
      ),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          // Logo + Name
          Flexible(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                  child: Image.asset(
                    'assets/images/Wordmark Logo with Upload Arrow and Magnifying Glass.png',
                    width: isSmallScreen ? 32 : 40,
                    height: isSmallScreen ? 32 : 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      return Container(
                        width: isSmallScreen ? 32 : 40,
                        height: isSmallScreen ? 32 : 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                        ),
                        child: Icon(
                          FontAwesomeIcons.scaleBalanced,
                          color: const Color(0xFF2563EB),
                          size: isSmallScreen ? 14 : 18,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 18 : (isLargeScreen ? 24 : 22),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Notification bell
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBellPressed,
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              child: Container(
                width: isSmallScreen ? 32 : 40,
                height: isSmallScreen ? 32 : 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
                child: Icon(
                  FontAwesomeIcons.bell,
                  size: isSmallScreen ? 14 : 16,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
