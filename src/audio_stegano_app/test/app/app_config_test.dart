import 'dart:convert';

import 'package:audio_stegano_app/app/app_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('assets/appsettings.json is bundled and has deploy keys', () async {
    final raw = await rootBundle.loadString('assets/appsettings.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    expect(map['DefaultFixedMessageBitLength'], 262144);
    expect(map['LogisticR'], 3.99);
    expect(map['LogisticX0'], 0.45);
    expect(map.containsKey('ShowEmbedLoadFileButton'), isTrue);
    expect(map.containsKey('ShowEmbedRecoveryDialog'), isTrue);
  });

  test('AppConfig.defaults matches appsettings baseline', () {
    expect(AppConfig.defaults.defaultFixedMessageBitLength, 262144);
    expect(AppConfig.defaults.logisticR, 3.99);
    expect(AppConfig.defaults.logisticX0, 0.45);
  });

  test('AppConfig.bundledAssetPaths includes stable asset key', () {
    expect(AppConfig.bundledAssetPaths, contains('assets/appsettings.json'));
  });

  test('showEmbedLoadFileForUiValue enables load on Windows desktop', () {
    expect(
      AppConfig.showEmbedLoadFileForUiValue(
        showEmbedLoadFileButton: false,
        isNativeWindowsDesktop: true,
      ),
      isTrue,
    );
    expect(
      AppConfig.showEmbedLoadFileForUiValue(
        showEmbedLoadFileButton: false,
        isNativeWindowsDesktop: false,
      ),
      isFalse,
    );
    expect(
      AppConfig.showEmbedLoadFileForUiValue(
        showEmbedLoadFileButton: true,
        isNativeWindowsDesktop: false,
      ),
      isTrue,
    );
  });
}
