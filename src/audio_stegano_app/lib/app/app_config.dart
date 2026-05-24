import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_config_loader.dart';

/// Deploy-time configuration from [appsettings.json] beside the app or bundled asset.
class AppConfig {
  final bool showEmbedLoadFileButton;
  final bool showEmbedRecoveryDialog;

  /// Fixed msg_len when default message bit limit is enabled (2^18 = 262144).
  final int defaultFixedMessageBitLength;

  /// Default logistic map [r] for new sessions / reset.
  final double logisticR;

  /// Default logistic map [x0] for new sessions / reset.
  final double logisticX0;

  const AppConfig({
    required this.showEmbedLoadFileButton,
    required this.showEmbedRecoveryDialog,
    required this.defaultFixedMessageBitLength,
    required this.logisticR,
    required this.logisticX0,
  });

  /// UI flag: on Windows desktop, file load stays available when deploy flag is false.
  static bool showEmbedLoadFileForUiValue({
    required bool showEmbedLoadFileButton,
    required bool isNativeWindowsDesktop,
  }) =>
      showEmbedLoadFileButton || isNativeWindowsDesktop;

  bool get showEmbedLoadFileForUi => showEmbedLoadFileForUiValue(
        showEmbedLoadFileButton: showEmbedLoadFileButton,
        isNativeWindowsDesktop:
            !kIsWeb && defaultTargetPlatform == TargetPlatform.windows,
      );

  static const AppConfig defaults = AppConfig(
    showEmbedLoadFileButton: false,
    showEmbedRecoveryDialog: true,
    defaultFixedMessageBitLength: 262144,
    logisticR: 3.99,
    logisticX0: 0.45,
  );

  /// Asset keys used after [tryLoadDeployAppSettingsJson] (web / IO beside exe).
  static const List<String> bundledAssetPaths = [
    'assets/appsettings.json',
    '../../appsettings.json',
  ];

  static AppConfig _parseJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return AppConfig(
      showEmbedLoadFileButton:
          map['ShowEmbedLoadFileButton'] as bool? ??
          defaults.showEmbedLoadFileButton,
      showEmbedRecoveryDialog:
          map['ShowEmbedRecoveryDialog'] as bool? ??
          defaults.showEmbedRecoveryDialog,
      defaultFixedMessageBitLength:
          (map['DefaultFixedMessageBitLength'] as num?)?.toInt() ??
          defaults.defaultFixedMessageBitLength,
      logisticR: (map['LogisticR'] as num?)?.toDouble() ?? defaults.logisticR,
      logisticX0:
          (map['LogisticX0'] as num?)?.toDouble() ?? defaults.logisticX0,
    );
  }

  static Future<String?> _loadBundledAsset() async {
    for (final path in bundledAssetPaths) {
      try {
        final raw = await rootBundle.loadString(path);
        if (raw.trim().isNotEmpty) {
          return raw;
        }
      } catch (_) {
        // Try next bundled path.
      }
    }
    return null;
  }

  static Future<AppConfig> load() async {
    try {
      final external = await tryLoadDeployAppSettingsJson();
      if (external != null && external.trim().isNotEmpty) {
        if (kDebugMode) {
          debugPrint('AppConfig: loaded from deploy file or web fetch');
        }
        return _parseJson(external);
      }

      final bundled = await _loadBundledAsset();
      if (bundled != null) {
        if (kDebugMode) {
          debugPrint('AppConfig: loaded from Flutter asset bundle');
        }
        return _parseJson(bundled);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AppConfig.load failed: $e\n$st');
      }
    }

    if (kDebugMode) {
      debugPrint('AppConfig: using compiled defaults');
    }
    return defaults;
  }
}
