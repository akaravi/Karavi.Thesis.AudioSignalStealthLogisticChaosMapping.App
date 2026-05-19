import 'dart:convert';

import 'package:flutter/services.dart';

/// Deploy-time configuration from [assets/app-config.json] (not user preferences).
class AppConfig {
  final bool showEmbedLoadFileButton;
  final bool showEmbedRecoveryDialog;

  const AppConfig({
    required this.showEmbedLoadFileButton,
    required this.showEmbedRecoveryDialog,
  });

  static const AppConfig defaults = AppConfig(
    showEmbedLoadFileButton: true,
    showEmbedRecoveryDialog: true,
  );

  static Future<AppConfig> load() async {
    try {
      final raw = await rootBundle.loadString('assets/app-config.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppConfig(
        showEmbedLoadFileButton:
            map['ShowEmbedLoadFileButton'] as bool? ??
            defaults.showEmbedLoadFileButton,
        showEmbedRecoveryDialog:
            map['ShowEmbedRecoveryDialog'] as bool? ??
            defaults.showEmbedRecoveryDialog,
      );
    } catch (_) {
      return defaults;
    }
  }
}
