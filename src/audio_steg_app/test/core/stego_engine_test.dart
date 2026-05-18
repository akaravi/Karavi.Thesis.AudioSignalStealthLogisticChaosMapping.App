import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_steg_app/core/audio/wav_io.dart';
import 'package:audio_steg_app/core/stego/stego.dart';
import 'package:flutter_test/flutter_test.dart';

WavFile _sineCover({int seconds = 4}) {
  const fs = 44100;
  final n = seconds * fs;
  final s = Int16List(n);
  for (var i = 0; i < n; i++) {
    s[i] = (math.sin(2 * math.pi * 440 * i / fs) * 32700).round().clamp(
      -32768,
      32767,
    );
  }
  return WavFile(sampleRate: fs, numChannels: 1, bitsPerSample: 16, samples: s);
}

void main() {
  group('StegoEngine — main_steganography.m flow', () {
    test('embed and extract round-trip with msg_len', () {
      final eng = StegoEngine();
      final cover = _sineCover();
      const msg = 'پیام کامل برای حالت دیجیتال.';
      final out = eng.embed(text: msg, cover: cover);
      final extracted = eng.extract(out.stego, out.bitsEmbedded);
      expect(extracted, msg);
    });

    test('reports evaluate_stego metrics', () {
      final eng = StegoEngine();
      final cover = _sineCover();
      const msg = 'metrics';
      final out = eng.embed(text: msg, cover: cover);
      expect(out.bitsEmbedded, greaterThan(0));
      expect(out.capacityBits, greaterThan(out.bitsEmbedded));
      expect(out.metrics.berPercent, 0.0);
      expect(out.metrics.snrDb, greaterThan(40));
      expect(out.metrics.npcrPercent, greaterThan(0.0));
    });

    test('wrong key returns null or wrong text', () {
      final engEnc = StegoEngine(x0: 0.45);
      final engDec = StegoEngine(x0: 0.46);
      final cover = _sineCover();
      final out = engEnc.embed(text: 'Secret', cover: cover);
      final extracted = engDec.extract(out.stego, out.bitsEmbedded);
      expect(extracted, isNot('Secret'));
    });
  });
}
