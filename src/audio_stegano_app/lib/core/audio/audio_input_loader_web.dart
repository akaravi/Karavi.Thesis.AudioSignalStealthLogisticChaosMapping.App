import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'audio_mp3_decoder.dart';
import 'wav_io.dart';

/// Web: WAV/MP3/MP4 from picker bytes ([audio_decoder] on web).
abstract final class AudioInputLoader {
  static const audioPickerExtensions = ['wav', 'mp3', 'mp4'];

  static Future<WavFile> loadPickedFile({
    required String fileName,
    Uint8List? bytes,
    String? path,
  }) async {
    if (bytes == null) {
      throw StateError('No file bytes for $fileName');
    }
    return loadFromBytes(bytes, fileName);
  }

  static Future<WavFile> loadFromBytes(Uint8List bytes, String fileName) async {
    final ext = p.extension(fileName).toLowerCase();
    return switch (ext) {
      '.wav' => WavFile.decode(bytes),
      '.mp3' => decodeMp3ToWav(bytes),
      '.mp4' => decodeMp4ToWav(bytes),
      _ => throw FormatException('Unsupported audio format: $ext'),
    };
  }

  static Future<WavFile> loadFromPath(String filePath) async {
    throw UnsupportedError('loadFromPath is not available on web');
  }
}
