import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ink & Trust tokens from [DESIGN.md].
abstract final class AppColors {
  static const paper = Color(0xFFF7F4EE);
  static const paper2 = Color(0xFFEFE9DF);
  static const cloud = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0A1F3D);
  static const inkSoft = Color(0xFF3D4F66);
  static const accentGold = Color(0xFFB8954A);
  static const rule = Color(0xFFD9D2C5);
  static const shadow = Color(0x140A1F3D);
  static const error = Color(0xFFB42318);

  // Compatibility aliases (legacy names used across widgets/pages).
  static const skyWash = paper;
  static const skyMist = paper2;
  static const primaryNavy = ink;
  static const accentSky = accentGold;
  static const accentSoft = paper2;
  static const progressIdle = Color(0xFFD4CDC0);
  static const brightBlue = accentGold;
  static const borderMuted = rule;

  static const riskLow = Color(0xFF1B6B3A);
  static const riskLowBg = Color(0xFFE8F5EE);
  static const riskMedium = Color(0xFF9A5B00);
  static const riskMediumBg = Color(0xFFFFF4E5);
  static const riskHigh = Color(0xFFB42318);
  static const riskHighBg = Color(0xFFFDECEC);
  static const riskMissing = Color(0xFF5A6A7A);
  static const riskMissingBg = Color(0xFFEEF2F6);
}

abstract final class AppRadii {
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const pill = 999.0;
  static const field = 12.0;
}

abstract final class AppSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 40.0;
  static const xxl = 56.0;
  static const screenH = 24.0;
}

abstract final class AppSizes {
  static const buttonHeight = 56.0;
  static const socialButtonHeight = 52.0;
  static const otpBox = 48.0;
}

ThemeData buildLegisenseTheme() {
  final epilogue = GoogleFonts.epilogueTextTheme();

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.ink,
      primary: AppColors.ink,
      surface: AppColors.paper,
      error: AppColors.error,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      titleTextStyle: GoogleFonts.spectral(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        fontStyle: FontStyle.normal,
      ),
    ),
    textTheme: epilogue.copyWith(
      displayLarge: GoogleFonts.spectral(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.4,
        color: AppColors.ink,
        fontStyle: FontStyle.normal,
      ),
      headlineMedium: GoogleFonts.spectral(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.ink,
        fontStyle: FontStyle.normal,
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
      labelLarge: GoogleFonts.spectral(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.cloud,
        fontStyle: FontStyle.normal,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.rule),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.rule),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.cloud),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accentGold;
        return AppColors.progressIdle;
      }),
    ),
    dividerColor: AppColors.rule,
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.cloud,
      selectedColor: AppColors.ink,
      side: const BorderSide(color: AppColors.rule),
      labelStyle: GoogleFonts.epilogue(fontWeight: FontWeight.w600),
    ),
  );
}
