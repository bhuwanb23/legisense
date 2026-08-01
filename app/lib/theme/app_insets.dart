import 'package:flutter/material.dart';

/// Clearance for the floating shell dock ([AppBottomNav]).
///
/// Dock geometry: pill 68 + margin 16 = 84, plus optional breathing room.
class AppInsets {
  AppInsets._();

  static const dockPill = 68.0;
  static const dockMargin = 16.0;
  static const dockBreathing = 16.0;

  /// For scroll bodies with [SafeArea] `bottom: false` (body draws under dock).
  /// Equals `100 + MediaQuery.padding.bottom`.
  static double shellBottom(BuildContext context) =>
      dockPill +
      dockMargin +
      dockBreathing +
      MediaQuery.paddingOf(context).bottom;

  /// Bottom padding inside a [SafeArea] that already pads the system inset
  /// (fixed footers: chat composer, plain-language actions, edit-profile).
  /// Do **not** add [MediaQuery.padding] again when using this.
  static const shellBottomInsideSafeArea = 100.0;
}
