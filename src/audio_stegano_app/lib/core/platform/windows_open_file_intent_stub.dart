import '../../app/opened_audio_file.dart';

/// Windows «Open with» events (native runner only).
abstract final class WindowsOpenFileIntent {
  static bool get isSupported => false;

  static Stream<OpenedAudioFile> watchOpens() => const Stream.empty();
}
