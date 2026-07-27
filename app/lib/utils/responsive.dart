import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 600;
  }
  
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }
  
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }
  
  static double getResponsivePadding(BuildContext context, {
    double small = 8.0,
    double medium = 16.0,
    double large = 24.0,
  }) {
    if (isSmallScreen(context)) return small;
    if (isLargeScreen(context)) return large;
    return medium;
  }
  
  static double getResponsiveFontSize(BuildContext context, {
    double small = 12.0,
    double medium = 14.0,
    double large = 16.0,
  }) {
    if (isSmallScreen(context)) return small;
    if (isLargeScreen(context)) return large;
    return medium;
  }
  
  static double getResponsiveIconSize(BuildContext context, {
    double small = 16.0,
    double medium = 20.0,
    double large = 24.0,
  }) {
    if (isSmallScreen(context)) return small;
    if (isLargeScreen(context)) return large;
    return medium;
  }
}
