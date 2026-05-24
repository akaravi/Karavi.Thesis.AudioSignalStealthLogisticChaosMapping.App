import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../app/opened_audio_file.dart';

const _eventChannel =
    EventChannel('ir.ntk.audiowmark.app/windows_open_file_events');

/// Secondary-instance «Open with» forwarded via named pipe (WPF parity).
abstract final class WindowsOpenFileIntent {
  /// Native EventChannel exists only in the Windows runner, not `flutter test`.
  static bool get isSupported =>
      Platform.isWindows && Platform.environment['FLUTTER_TEST'] != 'true';

  static Stream<OpenedAudioFile> watchOpens() {
    if (!isSupported) return const Stream.empty();
    return _eventChannel
        .receiveBroadcastStream()
        .map(_parsePath)
        .where((file) => file != null)
        .cast<OpenedAudioFile>();
  }

  static OpenedAudioFile? _parsePath(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return OpenedAudioFile(
      path: raw,
      displayName: p.basename(raw),
    );
  }
}
