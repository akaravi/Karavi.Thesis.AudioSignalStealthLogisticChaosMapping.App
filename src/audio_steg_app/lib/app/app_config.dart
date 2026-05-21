import 'dart:convert';

import 'package:flutter/services.dart';

import 'app_config_loader.dart';

/// Deploy-time configuration from [appsettings.json] beside the app or bundled asset.
class AppConfig {
  final bool showEmbedLoadFileButton;
  final bool showEmbedRecoveryDialog;

  const AppConfig({
    required this.showEmbedLoadFileButton,
    required this.showEmbedRecoveryDialog,
  });

  static const AppConfig defaults = AppConfig(
    showEmbedLoadFileButton: false,
    showEmbedRecoveryDialog: true,
  );

  static const String _bundledAssetPath = '../../appsettings.json';

  static AppConfig _parseJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return AppConfig(
      showEmbedLoadFileButton:
          map['ShowEmbedLoadFileButton'] as bool? ??
          defaults.showEmbedLoadFileButton,
      showEmbedRecoveryDialog:
          map['ShowEmbedRecoveryDialog'] as bool? ??
          defaults.showEmbedRecoveryDialog,
    );
  }

  static Future<AppConfig> load() async {
    try {
      final external = await tryLoadDeployAppSettingsJson();
      if (external != null && external.trim().isNotEmpty) {
        return _parseJson(external);
      }

      final raw = await rootBundle.loadString(_bundledAssetPath);
      return _parseJson(raw);
    } catch (_) {
      return defaults;
    }
  }
}
