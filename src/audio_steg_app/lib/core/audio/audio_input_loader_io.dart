import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../io/native_file.dart';
import 'audio_mp3_decoder.dart';
import 'wav_io.dart';

/// Loads WAV or MP3 bytes/paths into [WavFile] (mono PCM 16-bit).
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
    final bytes = await nativeReadBytes(filePath);
    return loadFromBytes(bytes, filePath);
  }
}
