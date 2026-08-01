import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../repositories/auth_repository.dart';
import '../services/api_exception.dart';
import '../services/session_prefs.dart';
import '../services/socket_service.dart';
import '../pages/auth/profile_setup_page.dart';
import '../pages/shell/main_shell.dart';

/// Shared OAuth + post-login navigation.
abstract final class AuthSocialActions {
  static final _google = GoogleSignIn.instance;

  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _google.initialize();
      final account = await _google.authenticate();
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(message: 'Google did not return an ID token');
      }
      await AuthRepository().oauthGoogle(idToken);
      await SocketService.instance.connect();
      if (!context.mounted) return;
      await _goHome(context);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      _toast(context, e.message);
    } catch (e) {
      if (!context.mounted) return;
      _toast(context, e.toString());
    }
  }

  static Future<void> signInWithFacebook(BuildContext context) async {
    if (kIsWeb) {
      _toast(
        context,
        'Facebook sign-in is available on the mobile app.',
      );
      return;
    }
    // Lightweight path: prompt for a Graph access token when the native
    // Facebook SDK is not configured in this build.
    final token = await showDialog<String>(
      context: context,
      builder: (context) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Facebook sign-in'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(
              hintText: 'Paste Facebook access token',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, c.text.trim()),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    if (token == null || token.isEmpty) return;
    try {
      await AuthRepository().oauthFacebook(token);
      await SocketService.instance.connect();
      if (!context.mounted) return;
      await _goHome(context);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      _toast(context, e.message);
    } catch (e) {
      if (!context.mounted) return;
      _toast(context, e.toString());
    }
  }

  static Future<void> _goHome(BuildContext context) async {
    final complete = await SessionPrefs.isProfileComplete();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => complete
            ? const MainShell()
            : const ProfileSetupPage(),
      ),
      (_) => false,
    );
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
