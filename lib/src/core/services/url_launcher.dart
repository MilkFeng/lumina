import 'package:url_launcher/url_launcher.dart';

class UrlLauncher {
  static Future<void> launch(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> canLaunch(Uri uri) async {
    return await canLaunchUrl(uri);
  }
}
