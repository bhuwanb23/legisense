import 'package:flutter/material.dart';

/// Clearance for the floating shell dock ([AppBottomNav]).
///
/// Dock geometry: pill 68 + margin 16 = 84 from the safe-area bottom.
class AppInsets {
  AppInsets._();

  static const dockPill = 68.0;
  static const dockMargin = 16.0;

  /// Air between content/footer and the dock top.
  static const dockBreathing = 8.0;

  /// Dock stack height above the system inset: 68 + 16 + 8 = 92.
  static const dockClearance = dockPill + dockMargin + dockBreathing;

  /// For scroll bodies with [SafeArea] `bottom: false`.
  static double shellBottom(BuildContext context) =>
      dockClearance + MediaQuery.paddingOf(context).bottom;

  /// Bottom offset for footers that should sit just above the dock.
  /// Prefer with [SafeArea] `bottom: false` so inset is applied only once.
  static double footerAboveDock(BuildContext context) =>
      dockClearance + MediaQuery.paddingOf(context).bottom;
}
