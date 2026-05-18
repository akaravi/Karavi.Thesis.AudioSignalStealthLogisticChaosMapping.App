import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'wav_io.dart';

/// Cross-platform WAV player. Writes the buffer to a temp file because
/// just_audio's `setAudioSource(BytesSource)` is not supported on every
/// desktop platform.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playWav(WavFile wav) async {
    final bytes = wav.encode();
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}${Platform.pathSeparator}'
        'play_${DateTime.now().millisecondsSinceEpoch}.wav';
    await File(path).writeAsBytes(bytes);
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<void> playFile(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<void> playBytes(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}${Platform.pathSeparator}'
        'play_${DateTime.now().millisecondsSinceEpoch}.wav';
    await File(path).writeAsBytes(bytes);
    await playFile(path);
  }

  Future<void> stop() => _player.stop();

  Stream<PlayerState> get stateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;

  Future<void> dispose() => _player.dispose();
}
