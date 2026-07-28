import 'package:shared_preferences/shared_preferences.dart';

/// First-run + auth session preferences (mock auth until backend exists).
class SessionPrefs {
  SessionPrefs._();

  static const _onboardingKey = 'has_seen_onboarding';
  static const _loggedInKey = 'is_logged_in';
  static const _profileCompleteKey = 'is_profile_complete';
  static const _rememberMeKey = 'remember_me';
  static const _emailKey = 'user_email';
  static const _displayNameKey = 'user_display_name';

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await _prefs;
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setOnboardingSeen([bool value = true]) async {
    final prefs = await _prefs;
    await prefs.setBool(_onboardingKey, value);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await _prefs;
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_loggedInKey, value);
  }

  static Future<bool> isProfileComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(_profileCompleteKey) ?? false;
  }

  static Future<void> setProfileComplete(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_profileCompleteKey, value);
  }

  static Future<bool> rememberMe() async {
    final prefs = await _prefs;
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  static Future<void> setRememberMe(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_rememberMeKey, value);
  }

  static Future<String?> userEmail() async {
    final prefs = await _prefs;
    return prefs.getString(_emailKey);
  }

  static Future<void> setUserEmail(String? email) async {
    final prefs = await _prefs;
    if (email == null || email.isEmpty) {
      await prefs.remove(_emailKey);
    } else {
      await prefs.setString(_emailKey, email);
    }
  }

  static Future<String?> displayName() async {
    final prefs = await _prefs;
    return prefs.getString(_displayNameKey);
  }

  static Future<void> setDisplayName(String? name) async {
    final prefs = await _prefs;
    if (name == null || name.isEmpty) {
      await prefs.remove(_displayNameKey);
    } else {
      await prefs.setString(_displayNameKey, name);
    }
  }

  /// Splash destination helper.
  static Future<SplashDestination> resolveSplashDestination() async {
    final loggedIn = await isLoggedIn();
    final profileDone = await isProfileComplete();
    if (loggedIn && profileDone) return SplashDestination.home;

    final onboardingSeen = await hasSeenOnboarding();
    if (onboardingSeen) return SplashDestination.login;
    return SplashDestination.onboarding;
  }

  /// Dev helper — clears first-run + auth flags.
  static Future<void> resetAll() async {
    final prefs = await _prefs;
    await prefs.remove(_onboardingKey);
    await prefs.remove(_loggedInKey);
    await prefs.remove(_profileCompleteKey);
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_displayNameKey);
  }
}

enum SplashDestination { onboarding, login, home }
