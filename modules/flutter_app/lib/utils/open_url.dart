import 'package:url_launcher/url_launcher.dart';

Future<void> openUri(Uri uri) async {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> openUrl(String url) => openUri(Uri.parse(url));
