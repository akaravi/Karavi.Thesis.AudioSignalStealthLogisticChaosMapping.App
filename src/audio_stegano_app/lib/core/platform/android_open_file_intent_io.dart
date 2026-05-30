import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../app/opened_audio_file.dart';

const _methodChannel = MethodChannel('ca.karavi.audiowmark.app/open_file');
const _eventChannel = EventChannel('ca.karavi.audiowmark.app/open_file_events');

/// Android ACTION_VIEW (Open with) for WAV / MP4.
abstract final class AndroidOpenFileIntent {
  static bool get isSupported => Platform.isAndroid;

  static Future<OpenedAudioFile?> consumeInitial() async {
    if (!isSupported) return null;
    final raw = await _methodChannel.invokeMethod<Map<dynamic, dynamic>?>(
      'getInitialOpenPayload',
    );
    return _parsePayload(raw);
  }

  static Stream<OpenedAudioFile> watchOpens() {
    if (!isSupported) return const Stream.empty();
    return _eventChannel
        .receiveBroadcastStream()
        .map(_parsePayload)
        .where((file) => file != null)
        .cast<OpenedAudioFile>();
  }

  static OpenedAudioFile? _parsePayload(dynamic raw) {
    if (raw is! Map) return null;
    final path = raw['path'];
    final displayName = raw['displayName'];
    if (path is! String || path.isEmpty) return null;
    if (displayName is! String || displayName.isEmpty) {
      return OpenedAudioFile(
        path: path,
        displayName: path.split(RegExp(r'[/\\]')).last,
      );
    }
    return OpenedAudioFile(path: path, displayName: displayName);
  }
}
