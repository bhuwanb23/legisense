import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TripGlide Operate tokens from [DESIGN.md].
abstract final class AppColors {
  static const bg = Color(0xFFF7F7F7);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1A1A1A);
  static const mute = Color(0xFF8A8A8A);
  static const chip = Color(0xFFEEEEEE);
  static const rule = Color(0xFFE8E8E8);
  static const shadow = Color(0x0F1A1A1A);
  static const error = Color(0xFFB42318);

  // Compatibility aliases used across existing pages.
  static const paper = bg;
  static const paper2 = chip;
  static const cloud = surface;
  static const inkSoft = mute;
  static const accentGold = ink;
  static const skyWash = bg;
  static const skyMist = bg;
  static const primaryNavy = ink;
  static const accentSky = ink;
  static const accentSoft = chip;
  static const progressIdle = Color(0xFFD0D0D0);
  static const brightBlue = ink;
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
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 32.0;
  static const pill = 999.0;
  static const field = 20.0;
}

abstract final class AppSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const screenH = 24.0;
}

abstract final class AppSizes {
  static const buttonHeight = 56.0;
  static const socialButtonHeight = 52.0;
  static const otpBox = 52.0;
}

abstract final class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.08),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}

ThemeData buildLegisenseTheme() {
  final base = GoogleFonts.plusJakartaSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.ink,
      primary: AppColors.ink,
      surface: AppColors.bg,
      error: AppColors.error,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
    textTheme: base.copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: AppColors.ink,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.ink,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.mute,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.mute,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.surface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: BorderSide.none,
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
      thumbColor: WidgetStateProperty.all(AppColors.surface),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.ink;
        return AppColors.progressIdle;
      }),
    ),
    dividerColor: AppColors.rule,
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.chip,
      selectedColor: AppColors.ink,
      side: BorderSide.none,
      labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
    ),
  );
}
