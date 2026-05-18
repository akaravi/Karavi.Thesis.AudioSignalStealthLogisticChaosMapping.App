import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'audio_mp3_decoder.dart';
import 'wav_io.dart';

/// Web: WAV/MP3 from picker bytes (MP3 via Web Audio API through [audio_decoder]).
abstract final class AudioInputLoader {
  static const audioPickerExtensions = ['wav', 'mp3'];

  static Future<WavFile> loadFromBytes(Uint8List bytes, String fileName) async {
    final ext = p.extension(fileName).toLowerCase();
    return switch (ext) {
      '.wav' => WavFile.decode(bytes),
      '.mp3' => decodeMp3ToWav(bytes),
      _ => throw FormatException('Unsupported audio format: $ext'),
    };
  }

  static Future<WavFile> loadFromPath(String filePath) async {
    throw UnsupportedError('loadFromPath is not available on web');
  }
}
