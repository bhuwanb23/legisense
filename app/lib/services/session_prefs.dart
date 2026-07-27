import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight first-run preferences for splash routing.
class SessionPrefs {
  SessionPrefs._();

  static const _onboardingKey = 'has_seen_onboarding';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Dev helper — clears first-run flag.
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }
}
