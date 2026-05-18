import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'wav_io.dart';

/// Loads WAV or MP3 bytes/paths into [WavFile] (mono PCM 16-bit).
abstract final class AudioInputLoader {
  static const audioPickerExtensions = ['wav', 'mp3'];

  static Future<WavFile> loadFromBytes(Uint8List bytes, String fileName) async {
    final ext = p.extension(fileName).toLowerCase();
    return switch (ext) {
      '.wav' => WavFile.decode(bytes),
      '.mp3' => _decodeMp3Bytes(bytes),
      _ => throw FormatException('Unsupported audio format: $ext'),
    };
  }

  static Future<WavFile> loadFromPath(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return loadFromBytes(bytes, filePath);
  }

  static Future<WavFile> _decodeMp3Bytes(Uint8List mp3Bytes) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final inPath = p.join(dir.path, 'decode_$stamp.in.mp3');
    final outPath = p.join(dir.path, 'decode_$stamp.out.wav');

    final input = File(inPath);
    final output = File(outPath);
    try {
      await input.writeAsBytes(mp3Bytes, flush: true);
      final session = await FFmpegKit.execute(
        '-y -i "$inPath" -ac 1 -ar 44100 -sample_fmt s16 "$outPath"',
      );
      final rc = await session.getReturnCode();
      if (!ReturnCode.isSuccess(rc) || !await output.exists()) {
        final logs = await session.getAllLogsAsString();
        throw StateError(
          'MP3 decode failed${logs == null || logs.isEmpty ? '' : ': $logs'}',
        );
      }
      return WavFile.decode(await output.readAsBytes());
    } finally {
      if (await input.exists()) await input.delete();
      if (await output.exists()) await output.delete();
    }
  }
}
