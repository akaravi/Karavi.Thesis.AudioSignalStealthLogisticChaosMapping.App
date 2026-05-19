import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../io/native_file.dart';
import 'audio_mp3_decoder.dart';
import 'wav_io.dart';

/// Loads WAV or MP3 bytes/paths into [WavFile] (mono PCM 16-bit).
abstract final class AudioInputLoader {
  static const audioPickerExtensions = ['wav', 'mp3'];

  /// Loads audio from a file picker result (path preferred on IO for MP3).
  static Future<WavFile> loadPickedFile({
    required String fileName,
    Uint8List? bytes,
    String? path,
  }) async {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.wav':
        final data =
            bytes ?? await nativeReadBytes(_requirePath(path, fileName));
        return WavFile.decode(data);
      case '.mp3':
        if (path != null && path.isNotEmpty) {
          try {
            return await decodeMp3ToWav(
              bytes ?? Uint8List(0),
              sourcePath: path,
            );
          } on StateError {
            rethrow;
          }
        }
        final mp3Bytes =
            bytes ?? await nativeReadBytes(_requirePath(path, fileName));
        return decodeMp3ToWav(mp3Bytes);
      default:
        throw FormatException('Unsupported audio format: $ext');
    }
  }

  static Future<WavFile> loadFromBytes(Uint8List bytes, String fileName) =>
      loadPickedFile(fileName: fileName, bytes: bytes);

  static Future<WavFile> loadFromPath(String filePath) =>
      loadPickedFile(fileName: filePath, path: filePath);

  static String _requirePath(String? path, String fileName) {
    if (path != null && path.isNotEmpty) {
      return path;
    }
    throw StateError('No file path for $fileName');
  }
}
