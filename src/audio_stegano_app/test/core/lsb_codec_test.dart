import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_stegano_app/core/audio/wav_io.dart';
import 'package:audio_stegano_app/core/stego/stego.dart';
import 'package:flutter_test/flutter_test.dart';

WavFile _sineCover({int seconds = 2, int sampleRate = 44100}) {
  final n = seconds * sampleRate;
  final samples = Int16List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    samples[i] = (math.sin(2 * math.pi * 440 * t) * 32700).round().clamp(
      -32768,
      32767,
    );
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
    test('embeds and extracts short text with known msg_len', () {
      final cover = _sineCover();
      final codec = LsbCodec();
      const msg = 'Hello World';
      final bits = MessageBits.fromUtf8Text(msg);
      final result = codec.embedText(cover, msg);
      expect(result.extractedMsg, equals(bits));
      final extract = codec.extractText(result.stego, bits.length);
      expect(extract.text, msg);
    });

    test('embeds and extracts longer paragraph', () {
      final cover = _sineCover(seconds: 4);
      final codec = LsbCodec();
      const msg =
          'Audio steganography is the art of hiding data inside an audio carrier.';
      final bits = MessageBits.fromUtf8Text(msg);
      final result = codec.embedText(cover, msg);
      expect(result.bitsEmbedded, bits.length);
      final extract = codec.extractText(result.stego, bits.length);
      expect(extract.text, msg);
    });
  });

  group('LSB Codec Persian/UTF-8', () {
    test('round-trip Persian text', () {
      final cover = _sineCover(seconds: 4);
      final codec = LsbCodec();
      const msg = 'سلام دنیا، این یک پیام نهان‌نگاری شده است.';
      final bits = MessageBits.fromUtf8Text(msg);
      final result = codec.embedText(cover, msg);
      final extract = codec.extractText(result.stego, bits.length);
      expect(extract.text, msg);
    });
  });

  group('LogisticPositions (train/logistic_positions.m)', () {
    test('positions are scattered not sequential prefix', () {
      final cover = _sineCover(seconds: 4);
      const msg = 'Hello World';
      final n = MessageBits.fromUtf8Text(msg).length;
      final pos = LogisticPositions.compute(
        n: n,
        maxPos: cover.samples.length,
        x0: 0.45,
        r: 3.99,
      );
      final sequential = List<int>.generate(n, (i) => i);
      expect(pos, isNot(equals(sequential)));
      expect(pos.length, n);
      expect(pos.toSet().length, n);
    });
  });

  group('LSB Codec security', () {
    test('wrong key (different x0) fails to recover correct text', () {
      final cover = _sineCover();
      final encoder = LsbCodec(x0: 0.45);
      final decoder = LsbCodec(x0: 0.46);
      const msg = 'TopSecret';
      final bits = MessageBits.fromUtf8Text(msg);
      final result = encoder.embedText(cover, msg);
      final extract = decoder.extractText(result.stego, bits.length);
      expect(extract.text, isNot('TopSecret'));
    });

    test('capacity check', () {
      final cover = _sineCover(seconds: 1);
      final codec = LsbCodec();
      final tooLong = 'X' * (cover.samples.length);
      expect(() => codec.embedText(cover, tooLong), throwsArgumentError);
    });
  });

  group('Metrics (evaluate_stego.m)', () {
    test('SNR is high and BER is 0 after correct embed_extract', () {
      final cover = _sineCover(seconds: 2);
      final codec = LsbCodec();
      const msg = 'Quality test of LSB embedding.';
      final bits = MessageBits.fromUtf8Text(msg);
      final result = codec.embedText(cover, msg);
      final stegoDiff = codec.stegoWithPerturbedKey(cover, bits);
      final mono = cover.toMono();

      final metrics = StegoMetrics.evaluate(
        cover: mono.samples,
        stego: result.stego.samples,
        originalBits: bits,
        extractedBits: result.extractedMsg,
        stegoWithDiffKey: stegoDiff.samples,
      );
      expect(metrics.berPercent, 0.0);
      expect(metrics.snrDb, greaterThan(50.0));
      expect(metrics.npcrPercent, greaterThan(0.0));
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
      final codec = LsbCodec();
      const msg = 'پیام کامل با pipeline کامل WAV.';
      final bits = MessageBits.fromUtf8Text(msg);
      final stego = codec.embedText(cover, msg).stego;
      final wavBytes = stego.encode();
      final reloaded = WavFile.decode(wavBytes);
      final extract = codec.extractText(reloaded, bits.length);
      expect(extract.text, msg);
    });
  });
}
