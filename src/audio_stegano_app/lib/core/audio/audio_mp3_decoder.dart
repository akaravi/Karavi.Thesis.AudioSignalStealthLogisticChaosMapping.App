import 'package:audio_decoder/audio_decoder.dart';
import 'package:flutter/foundation.dart';

import 'audio_mp3_decode_path.dart'
    if (dart.library.html) 'audio_mp3_decode_path_stub.dart'
    as path_decode;
import 'wav_io.dart';

/// Decodes MP3 bytes to mono PCM 16-bit @ 44.1 kHz.
///
/// On IO, prefers [sourcePath] when provided (more reliable than in-memory
/// conversion on Android). Falls back to a temp file + path decode, then
/// [AudioDecoder.convertToWavBytes] on web.
Future<WavFile> decodeMp3ToWav(Uint8List mp3Bytes, {String? sourcePath}) async {
  if (!kIsWeb) {
    if (sourcePath != null && sourcePath.isNotEmpty) {
      try {
        return await path_decode.decodeMp3FromPath(sourcePath);
      } on StateError {
        rethrow;
      } catch (_) {
        // Fall through to bytes-based decode.
      }
    }
    if (mp3Bytes.isEmpty) {
      throw StateError('MP3 decode failed: no audio data');
    }
    try {
      return await path_decode.decodeMp3BytesViaTempFile(mp3Bytes);
    } on StateError {
      rethrow;
    } catch (e) {
      throw StateError('MP3 decode failed: $e');
    }
  }

  try {
    final wavBytes = await AudioDecoder.convertToWavBytes(
      mp3Bytes,
      formatHint: 'mp3',
      sampleRate: 44100,
      channels: 1,
      bitDepth: 16,
    );
    final wav = WavFile.decode(wavBytes);
    if (!wav.isPcm16Mono) {
      return wav.toMono();
    }
    return wav;
  } on AudioConversionException catch (e) {
    throw StateError('MP3 decode failed: ${e.message}');
  }
}

/// Decodes MP4 (audio track) to mono PCM 16-bit @ 44.1 kHz.
Future<WavFile> decodeMp4ToWav(Uint8List mp4Bytes, {String? sourcePath}) async {
  if (!kIsWeb) {
    if (sourcePath != null && sourcePath.isNotEmpty) {
      try {
        return await path_decode.decodeMp4FromPath(sourcePath);
      } on StateError {
        rethrow;
      } catch (_) {
        // Fall through to bytes-based decode.
      }
    }
    if (mp4Bytes.isEmpty) {
      throw StateError('MP4 decode failed: no audio data');
    }
    try {
      return await path_decode.decodeMp4BytesViaTempFile(mp4Bytes);
    } on StateError {
      rethrow;
    } catch (e) {
      throw StateError('MP4 decode failed: $e');
    }
  }

  try {
    final wavBytes = await AudioDecoder.convertToWavBytes(
      mp4Bytes,
      formatHint: 'mp4',
      sampleRate: 44100,
      channels: 1,
      bitDepth: 16,
    );
    final wav = WavFile.decode(wavBytes);
    if (!wav.isPcm16Mono) {
      return wav.toMono();
    }
    return wav;
  } on AudioConversionException catch (e) {
    throw StateError('MP4 decode failed: ${e.message}');
  }
}
