import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT access + refresh tokens.
class TokenStore {
  TokenStore._();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<String?> accessToken() async =>
      (await _prefs).getString(_accessKey);

  static Future<String?> refreshToken() async =>
      (await _prefs).getString(_refreshKey);

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
  }

  static Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  static Future<bool> hasTokens() async {
    final access = await accessToken();
    final refresh = await refreshToken();
    return (access != null && access.isNotEmpty) ||
        (refresh != null && refresh.isNotEmpty);
  }
}
