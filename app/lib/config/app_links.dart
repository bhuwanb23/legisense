import 'package:url_launcher/url_launcher.dart';

/// Legal / support links used across auth and help screens.
abstract final class AppLinks {
  static const terms = 'https://legisense.app/terms';
  static const privacy = 'https://legisense.app/privacy';
  static const supportEmail = 'support@legisense.app';

  static Future<bool> open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> openMailto(String email, {String? subject}) {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null) 'subject': subject,
      },
    );
    return launchUrl(uri);
  }
}
