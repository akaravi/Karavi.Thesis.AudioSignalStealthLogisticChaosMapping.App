import 'dart:io';
import 'dart:typed_data';

import 'package:audio_decoder/audio_decoder.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'wav_io.dart';

/// Decodes compressed audio (MP3, MP4, …) via native [AudioDecoder.convertToWav].
Future<WavFile> decodeMediaFromPath(String inputPath) async {
  final outDir = await getTemporaryDirectory();
  final outPath = p.join(
    outDir.path,
    'decoded_${DateTime.now().microsecondsSinceEpoch}.wav',
  );
  try {
    await AudioDecoder.convertToWav(
      inputPath,
      outPath,
      sampleRate: 44100,
      channels: 1,
      bitDepth: 16,
    );
    final wav = WavFile.decode(await File(outPath).readAsBytes());
    if (!wav.isPcm16Mono) {
      return wav.toMono();
    }
    return wav;
  } on AudioConversionException catch (e) {
    throw StateError('Media decode failed: ${e.message}');
  } finally {
    final out = File(outPath);
    if (out.existsSync()) {
      await out.delete();
    }
  }
}

/// Decodes MP3 via [decodeMediaFromPath].
Future<WavFile> decodeMp3FromPath(String inputPath) =>
    decodeMediaFromPath(inputPath);

/// Decodes MP4/M4A via [decodeMediaFromPath].
Future<WavFile> decodeMp4FromPath(String inputPath) =>
    decodeMediaFromPath(inputPath);

/// Writes [mp3Bytes] to a temp `.mp3` then decodes via [decodeMediaFromPath].
Future<WavFile> decodeMp3BytesViaTempFile(Uint8List mp3Bytes) async {
  final dir = await getTemporaryDirectory();
  final tempIn = File(
    p.join(dir.path, 'input_${DateTime.now().microsecondsSinceEpoch}.mp3'),
  );
  try {
    await tempIn.writeAsBytes(mp3Bytes, flush: true);
    return await decodeMediaFromPath(tempIn.path);
  } finally {
    if (tempIn.existsSync()) {
      await tempIn.delete();
    }
  }
}

/// Writes [mp4Bytes] to a temp `.mp4` then decodes via [decodeMediaFromPath].
Future<WavFile> decodeMp4BytesViaTempFile(Uint8List mp4Bytes) async {
  final dir = await getTemporaryDirectory();
  final tempIn = File(
    p.join(dir.path, 'input_${DateTime.now().microsecondsSinceEpoch}.mp4'),
  );
  try {
    await tempIn.writeAsBytes(mp4Bytes, flush: true);
    return await decodeMediaFromPath(tempIn.path);
  } finally {
    if (tempIn.existsSync()) {
      await tempIn.delete();
    }
  }
}
