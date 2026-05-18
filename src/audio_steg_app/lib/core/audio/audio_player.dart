import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/session_log.dart';
import 'spectrum_analyzer.dart';
import 'wav_io.dart';

/// Cross-platform WAV player with spectrum stream for equalizer UI.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<List<double>> _spectrumController =
      StreamController<List<double>>.broadcast();

  List<List<double>>? _spectrumFrames;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  Stream<List<double>> get spectrumStream => _spectrumController.stream;
  Stream<PlayerState> get stateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  bool get isPlaying => _player.playing;

  Future<void> playWav(WavFile wav) async {
    await stop();
    _spectrumFrames = await compute(SpectrumAnalyzer.timelineFromWav, wav);
    final bytes = wav.encode();
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}${Platform.pathSeparator}'
        'play_${DateTime.now().millisecondsSinceEpoch}.wav';
    await File(path).writeAsBytes(bytes);
    await _player.setFilePath(path);
    _attachSpectrumListeners();
    await _player.play();
  }

  Future<void> playFile(String path) async {
    await stop();
    final bytes = await File(path).readAsBytes();
    final wav = WavFile.decode(bytes);
    await playWav(wav);
  }

  Future<void> playBytes(Uint8List bytes) async {
    final wav = WavFile.decode(bytes);
    await playWav(wav);
  }

  void _attachSpectrumListeners() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _positionSub = _player.positionStream.listen((pos) {
      final frames = _spectrumFrames;
      final dur = _player.duration;
      if (frames == null ||
          frames.isEmpty ||
          dur == null ||
          dur.inMilliseconds <= 0) {
        return;
      }
      final ratio = pos.inMilliseconds / dur.inMilliseconds;
      final idx = (ratio * (frames.length - 1)).round().clamp(
        0,
        frames.length - 1,
      );
      if (!_spectrumController.isClosed) {
        _spectrumController.add(frames[idx]);
      }
    });
    _stateSub = _player.playerStateStream.listen((st) {
      if (st.processingState == ProcessingState.completed &&
          !_spectrumController.isClosed) {
        _spectrumController.add(List<double>.filled(kSpectrumBandCount, 0));
      }
    });
  }

  Future<void> stop() async {
    _positionSub?.cancel();
    _positionSub = null;
    _stateSub?.cancel();
    _stateSub = null;
    _spectrumFrames = null;
    try {
      await _player.stop();
    } catch (e, st) {
      SessionLog.write('AudioPlayer: stop failed', error: e, stack: st);
    }
    if (!_spectrumController.isClosed) {
      _spectrumController.add(List<double>.filled(kSpectrumBandCount, 0));
    }
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _player.dispose();
    } catch (e, st) {
      SessionLog.write('AudioPlayer: dispose failed', error: e, stack: st);
    }
    await _spectrumController.close();
  }
}
