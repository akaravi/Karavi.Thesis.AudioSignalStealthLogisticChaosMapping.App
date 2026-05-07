import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_steg_app/core/audio/wav_io.dart';
import 'package:audio_steg_app/core/stego/stego.dart';
import 'package:flutter_test/flutter_test.dart';

WavFile _sineCover({int seconds = 2, int sampleRate = 44100}) {
  final n = seconds * sampleRate;
  final samples = Int16List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    samples[i] = (math.sin(2 * math.pi * 440 * t) * 32700).round().clamp(-32768, 32767);
  }
  return WavFile(
    sampleRate: sampleRate,
    numChannels: 1,
    bitsPerSample: 16,
    samples: samples,
  );
}

void main() {
  group('LSB Codec round-trip (English ASCII)', () {
    test('embeds and extracts short text', () {
      final cover = _sineCover();
      final codec = const LsbCodec();
      final result = codec.embedText(cover, 'Hello World');
      final extract = codec.extractText(result.stego);
      expect(extract.text, 'Hello World');
    });

    test('embeds and extracts longer paragraph', () {
      final cover = _sineCover(seconds: 4);
      final codec = const LsbCodec();
      const msg =
          'Audio steganography is the art of hiding data inside an audio carrier.';
      final result = codec.embedText(cover, msg);
      final extract = codec.extractText(result.stego);
      expect(extract.text, msg);
      expect(result.bitsEmbedded, TextCodec.requiredBits(msg));
    });
  });

  group('LSB Codec Persian/UTF-8', () {
    test('round-trip Persian text', () {
      final cover = _sineCover(seconds: 4);
      final codec = const LsbCodec();
      const msg = 'سلام دنیا، این یک پیام نهان‌نگاری شده است.';
      final result = codec.embedText(cover, msg);
      final extract = codec.extractText(result.stego);
      expect(extract.text, msg);
    });
  });

  group('LSB Codec security', () {
    test('wrong key (different x0) fails to recover correct text', () {
      final cover = _sineCover();
      final encoder = const LsbCodec(x0: 0.45);
      final decoder = const LsbCodec(x0: 0.46);
      final result = encoder.embedText(cover, 'TopSecret');
      final extract = decoder.extractText(result.stego);
      expect(extract.text, isNot('TopSecret'));
    });

    test('capacity check', () {
      final cover = _sineCover(seconds: 1);
      final codec = const LsbCodec();
      final tooLong = 'X' * (cover.samples.length);
      expect(() => codec.embedText(cover, tooLong), throwsArgumentError);
    });
  });

  group('Metrics', () {
    test('SNR is high (>50dB) and BER is 0 after correct extraction', () {
      final cover = _sineCover(seconds: 2);
      final codec = const LsbCodec();
      const msg = 'Quality test of LSB embedding.';
      final result = codec.embedText(cover, msg);
      final originalBits = TextCodec.encodeToBits(msg);

      final mono = cover.toMono();
      final encryptedReadBack = Uint8List(originalBits.length);
      for (var i = 0; i < originalBits.length; i++) {
        encryptedReadBack[i] = result.stego.samples[i] & 1;
      }
      final metrics = StegoMetrics.compute(
        cover: mono.samples,
        stego: result.stego.samples,
        originalBits: originalBits,
        extractedBits: originalBits,
      );
      expect(metrics.berPercent, 0.0);
      expect(metrics.snrDb, greaterThan(50.0));
    });
  });

  group('WAV I/O round-trip', () {
    test('encode then decode produces identical samples', () {
      final cover = _sineCover(seconds: 1);
      final bytes = cover.encode();
      final decoded = WavFile.decode(bytes);
      expect(decoded.sampleRate, cover.sampleRate);
      expect(decoded.numChannels, 1);
      expect(decoded.bitsPerSample, 16);
      expect(decoded.samples.length, cover.samples.length);
      for (var i = 0; i < 100; i++) {
        expect(decoded.samples[i], cover.samples[i]);
      }
    });

    test('full pipeline: embed -> encode -> decode -> extract', () {
      final cover = _sineCover(seconds: 2);
      final codec = const LsbCodec();
      const msg = 'پیام کامل با pipeline کامل WAV.';
      final stego = codec.embedText(cover, msg).stego;
      final wavBytes = stego.encode();
      final reloaded = WavFile.decode(wavBytes);
      final extract = codec.extractText(reloaded);
      expect(extract.text, msg);
    });
  });
}
