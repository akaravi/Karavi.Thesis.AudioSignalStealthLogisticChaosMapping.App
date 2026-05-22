// Web-only: fetches deploy-time appsettings.json from the app origin.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// Fetches [appsettings.json] from the web app root (respects base-href).
Future<String?> tryLoadDeployAppSettingsJson() async {
  try {
    final uri = Uri.base.resolve('appsettings.json');
    final response = await html.HttpRequest.request(
      uri.toString(),
      method: 'GET',
      responseType: 'text',
    );
    final text = response.responseText;
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    return text;
  } catch (_) {
    return null;
  }
}
