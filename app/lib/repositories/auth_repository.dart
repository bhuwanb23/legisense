import '../services/api_client.dart';
import '../services/session_prefs.dart';
import '../services/socket_service.dart';
import '../services/token_store.dart';
import '../models/api/auth_models.dart';

class AuthRepository {
  AuthRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<AuthTokens> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? profession,
  }) async {
    final tokens = await _api.post(
      '/api/auth/register',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (profession != null) 'profession': profession,
      },
      parse: (d) => AuthTokens.fromJson(d as Map<String, dynamic>),
    );
    await _persistSession(tokens);
    return tokens;
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final tokens = await _api.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
      parse: (d) => AuthTokens.fromJson(d as Map<String, dynamic>),
    );
    await _persistSession(tokens);
    return tokens;
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } catch (_) {
      // Still clear local session.
    }
    await SocketService.instance.disconnect();
    await TokenStore.clear();
    await SessionPrefs.setLoggedIn(false);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _api.post(
      '/api/auth/forgot-password',
      data: {'email': email},
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.post(
      '/api/auth/reset-password',
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  Future<UserProfile> getProfile() async {
    return _api.get(
      '/api/users/profile',
      parse: (d) => UserProfile.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<UserProfile> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? profession,
    String? profilePhotoUrl,
  }) async {
    final profile = await _api.put(
      '/api/users/profile',
      data: {
        if (fullName != null) 'fullName': fullName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (profession != null) 'profession': profession,
        if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      },
      parse: (d) => UserProfile.fromJson(d as Map<String, dynamic>),
    );
    if (profile.fullName != null) {
      await SessionPrefs.setDisplayName(profile.fullName);
    }
    if (profile.profession != null) {
      await SessionPrefs.setProfession(profile.profession);
    }
    return profile;
  }

  Future<void> updatePreferences({
    String? preferredLanguage,
    String? defaultJurisdiction,
    String? nickname,
    List<String>? preferredDocumentTypes,
  }) async {
    await _api.put(
      '/api/users/preferences',
      data: {
        if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
        if (defaultJurisdiction != null)
          'defaultJurisdiction': defaultJurisdiction,
        if (nickname != null) 'nickname': nickname,
        if (preferredDocumentTypes != null)
          'preferredDocumentTypes': preferredDocumentTypes,
      },
    );
    if (preferredLanguage != null) {
      await SessionPrefs.setLanguage(preferredLanguage);
    }
    if (defaultJurisdiction != null) {
      await SessionPrefs.setStateRegion(defaultJurisdiction);
    }
    if (nickname != null) {
      await SessionPrefs.setNickname(nickname);
    }
  }

  Future<void> deleteAccount() async {
    await _api.delete('/api/users/account');
    await SocketService.instance.disconnect();
    await TokenStore.clear();
    await SessionPrefs.setLoggedIn(false);
  }

  Future<void> _persistSession(AuthTokens tokens) async {
    await TokenStore.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await SessionPrefs.setLoggedIn(true);
    final user = tokens.user;
    if (user != null) {
      await SessionPrefs.setUserEmail(user.email);
      if (user.fullName != null) {
        await SessionPrefs.setDisplayName(user.fullName);
      }
    }
  }
}
