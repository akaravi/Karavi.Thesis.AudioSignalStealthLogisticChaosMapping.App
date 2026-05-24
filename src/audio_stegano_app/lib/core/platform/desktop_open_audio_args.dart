import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../app/opened_audio_file.dart';
import 'platform.dart';

/// Command-line audio path from Explorer «Open with» or double-click (desktop VM).
abstract final class DesktopOpenAudioArgs {
  static OpenedAudioFile? consumeInitial() {
    if (kIsWeb || !isDesktopNative) return null;

    for (final raw in Platform.executableArguments) {
      if (raw.startsWith('-')) continue;
      final path = raw.replaceAll('"', '').trim();
      if (!_isSupportedExtension(path)) continue;
      if (!File(path).existsSync()) continue;
      return OpenedAudioFile(
        path: path,
        displayName: p.basename(path),
      );
    }
    return null;
  }

  static bool _isSupportedExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.wav' || ext == '.mp3' || ext == '.mp4';
  }
}
