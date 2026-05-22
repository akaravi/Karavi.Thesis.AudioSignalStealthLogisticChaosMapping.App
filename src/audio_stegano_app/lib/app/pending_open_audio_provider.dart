import 'package:flutter_riverpod/legacy.dart';

import 'opened_audio_file.dart';

class PendingOpenAudioController extends StateNotifier<OpenedAudioFile?> {
  PendingOpenAudioController() : super(null);

  void setPending(OpenedAudioFile? file) => state = file;

  void clear() => state = null;
}

/// Set when the user opens a WAV/MP4 with this app; consumed by [ExtractScreen].
final pendingOpenAudioFileProvider =
    StateNotifierProvider<PendingOpenAudioController, OpenedAudioFile?>(
      (ref) => PendingOpenAudioController(),
    );
