import 'dart:typed_data';

import 'package:audio_decoder/audio_decoder.dart';

import 'wav_io.dart';

/// Decodes MP3 bytes to mono PCM 16-bit @ 44.1 kHz via native/Web Audio APIs.
Future<WavFile> decodeMp3ToWav(Uint8List mp3Bytes) async {
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
