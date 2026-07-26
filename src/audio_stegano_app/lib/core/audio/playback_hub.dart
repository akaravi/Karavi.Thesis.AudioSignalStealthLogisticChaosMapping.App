import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'audio_player.dart';
import 'wav_io.dart';

/// One isolated engine per UI play surface — no shared mutable play source.
enum PlaybackSessionId {
  embedCover,
  embedStego,
  embedPayloadOriginal,
  embedPayloadRecovered,
  extractCover,
  extractPayload,
}

/// Method-based exclusive playback: each session owns its [AudioPlayerService];
/// [play] / [playOrToggle] pause every other session first.
final class PlaybackHub {
  PlaybackHub._();
  static final PlaybackHub instance = PlaybackHub._();

  final Map<PlaybackSessionId, AudioPlayerService> _engines = {};

  static const embedSessions = <PlaybackSessionId>[
    PlaybackSessionId.embedCover,
    PlaybackSessionId.embedStego,
    PlaybackSessionId.embedPayloadOriginal,
    PlaybackSessionId.embedPayloadRecovered,
  ];

  static const extractSessions = <PlaybackSessionId>[
    PlaybackSessionId.extractCover,
    PlaybackSessionId.extractPayload,
  ];

  static const abSessions = <PlaybackSessionId>[
    PlaybackSessionId.embedCover,
    PlaybackSessionId.embedStego,
  ];

  AudioPlayerService engine(PlaybackSessionId id) =>
      _engines.putIfAbsent(id, AudioPlayerService.new);

  bool isPlaying(PlaybackSessionId id) => _engines[id]?.isPlaying ?? false;

  bool hasSource(PlaybackSessionId id) => _engines[id]?.hasSource ?? false;

  PlaybackSessionId? get activePlaying {
    for (final id in PlaybackSessionId.values) {
      if (isPlaying(id)) return id;
    }
    return null;
  }

  /// Start [wav] on [id]; pauses all other sessions (no cross-button swap).
  Future<void> play(PlaybackSessionId id, WavFile wav) async {
    await pauseOthers(id);
    await engine(id).playWav(wav);
  }

  /// If [id] is playing → pause. If paused with source → resume (after pausing
  /// others). Otherwise load and play [wav].
  Future<void> playOrToggle(PlaybackSessionId id, WavFile wav) async {
    final e = engine(id);
    if (e.isPlaying) {
      await e.pause();
      return;
    }
    if (e.hasSource) {
      await pauseOthers(id);
      await e.resume();
      return;
    }
    await play(id, wav);
  }

  /// Play without restarting when already playing the same session.
  Future<void> playIfNotPlaying(PlaybackSessionId id, WavFile wav) async {
    final e = engine(id);
    if (e.isPlaying) return;
    if (e.hasSource) {
      await pauseOthers(id);
      await e.resume();
      return;
    }
    await play(id, wav);
  }

  Future<void> pause(PlaybackSessionId id) async {
    await _engines[id]?.pause();
  }

  Future<void> stop(PlaybackSessionId id) async {
    await _engines[id]?.stop();
  }

  Future<void> pauseOthers(PlaybackSessionId keep) async {
    final futures = <Future<void>>[];
    for (final entry in _engines.entries) {
      if (entry.key == keep) continue;
      if (entry.value.isPlaying) {
        futures.add(entry.value.pause());
      }
    }
    if (futures.isNotEmpty) await Future.wait(futures);
  }

  Future<void> pauseSessions(Iterable<PlaybackSessionId> ids) async {
    await Future.wait(ids.map((id) async {
      await _engines[id]?.pause();
    }));
  }

  Future<void> stopSessions(Iterable<PlaybackSessionId> ids) async {
    await Future.wait(ids.map((id) async {
      await _engines[id]?.stop();
    }));
  }

  Future<void> stopAll() => stopSessions(PlaybackSessionId.values);

  StreamSubscription<PlayerState> listenState(
    PlaybackSessionId id,
    void Function(PlayerState state) onData,
  ) {
    return engine(id).stateStream.listen(onData);
  }

  StreamSubscription<List<double>> listenSpectrum(
    PlaybackSessionId id,
    void Function(List<double> bands) onData,
  ) {
    return engine(id).spectrumStream.listen(onData);
  }
}
