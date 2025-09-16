import 'package:flutter/material.dart';

class SimStyles {
  SimStyles._();

  // Spacing
  static const double spaceXS = 6;
  static const double spaceS = 10;
  static const double spaceM = 14;
  static const double spaceL = 18;

  // Radii
  static const double radiusS = 10;
  static const double radiusM = 12;
  static const double radiusL = 16;

  // Section container used across components
  static BoxDecoration sectionDecoration({Color background = Colors.white}) {
    return BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(radiusL),
      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static const EdgeInsets sectionPadding = EdgeInsets.all(spaceL);

  // Badge helper
  static BoxDecoration badgeDecoration(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
    );
  }

  static BoxDecoration insetCard({Color? color, Color? borderColor}) {
    return BoxDecoration(
      color: (color ?? Colors.white).withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(radiusM),
      border: Border.all(color: borderColor ?? const Color(0xFFE5E7EB), width: 1),
    );
  }
}


