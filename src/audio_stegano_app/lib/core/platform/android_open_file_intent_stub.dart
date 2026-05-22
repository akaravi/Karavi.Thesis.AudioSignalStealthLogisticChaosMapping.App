import '../../app/opened_audio_file.dart';

/// No-op on web and non-Android platforms.
abstract final class AndroidOpenFileIntent {
  static Future<OpenedAudioFile?> consumeInitial() async => null;

  static Stream<OpenedAudioFile> watchOpens() => const Stream.empty();
}
