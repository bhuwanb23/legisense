import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens from [DESIGN.md].
abstract final class AppColors {
  static const skyWash = Color(0xFFEAF3FB);
  static const skyMist = Color(0xFFF7FBFE);
  static const cloud = Color(0xFFFFFFFF);
  static const primaryNavy = Color(0xFF0B2C5E);
  static const inkSoft = Color(0xFF3A5A80);
  static const accentSky = Color(0xFF7EB6E8);
  static const accentSoft = Color(0xFFB7D6F2);
  static const progressIdle = Color(0xFFC9DDF0);
  static const shadow = Color(0x140B2C5E);
  static const error = Color(0xFFB42318);
  static const borderMuted = Color(0xFFD7E6F5);
}

abstract final class AppRadii {
  static const sm = 12.0;
  static const md = 24.0;
  static const lg = 32.0;
  static const pill = 999.0;
  static const field = 18.0;
}

abstract final class AppSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 40.0;
  static const xxl = 56.0;
  static const screenH = 28.0;
}

abstract final class AppSizes {
  static const buttonHeight = 56.0;
  static const socialButtonHeight = 52.0;
  static const otpBox = 50.0;
}

ThemeData buildLegisenseTheme() {
  final epilogue = GoogleFonts.epilogueTextTheme();
  final spectral = GoogleFonts.spectral();

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.skyWash,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryNavy,
      primary: AppColors.primaryNavy,
      surface: AppColors.skyMist,
      error: AppColors.error,
      brightness: Brightness.light,
    ),
    textTheme: epilogue.copyWith(
      displayLarge: GoogleFonts.epilogue(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
        color: AppColors.primaryNavy,
      ),
      headlineMedium: GoogleFonts.epilogue(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.primaryNavy,
      ),
      titleMedium: GoogleFonts.epilogue(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: AppColors.inkSoft,
      ),
      bodyMedium: GoogleFonts.epilogue(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.inkSoft,
      ),
      labelLarge: spectral.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.2,
        color: AppColors.primaryNavy,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cloud,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.accentSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.accentSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.cloud;
        return AppColors.cloud;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accentSky;
        return AppColors.progressIdle;
      }),
    ),
  );
}
