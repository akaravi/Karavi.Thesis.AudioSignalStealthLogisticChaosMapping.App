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
  group('StegoEngine — Digital mode', () {
    test('embed and extract round-trip', () {
      const eng = StegoEngine();
      final cover = _sineCover();
      const msg = 'پیام کامل برای حالت دیجیتال.';
      final out = eng.embed(mode: StegoMode.digital, text: msg, cover: cover);
      expect(out.mode, StegoMode.digital);
      final extracted = eng.extract(out.stego, mode: StegoMode.digital);
      expect(extracted, msg);
    });

    test('reports bitsEmbedded, capacityBits, and SNR metrics', () {
      const eng = StegoEngine();
      final cover = _sineCover();
      const msg = 'metrics';
      final out = eng.embed(mode: StegoMode.digital, text: msg, cover: cover);
      expect(out.bitsEmbedded, greaterThan(0));
      expect(out.capacityBits, greaterThan(out.bitsEmbedded));
      expect(out.metrics, isNotNull);
      // SNR for LSB on a sine wave is typically 80+ dB.
      expect(out.metrics!.snrDb, greaterThan(40));
    });
  });

  group('StegoEngine — Over-the-Air mode', () {
    test('synthesize FSK without cover and decode', () {
      const eng = StegoEngine();
      const msg = 'OTA Hello';
      final out = eng.embed(mode: StegoMode.overTheAir, text: msg);
      expect(out.mode, StegoMode.overTheAir);
      final extracted = eng.extract(out.stego, mode: StegoMode.overTheAir);
      expect(extracted, msg);
    });
  });

  group('StegoEngine — auto-detect mode', () {
    test('auto detects digital LSB when no FSK is present', () {
      const eng = StegoEngine();
      final cover = _sineCover();
      final out = eng.embed(
        mode: StegoMode.digital,
        text: 'Auto',
        cover: cover,
      );
      expect(eng.extract(out.stego), 'Auto');
    });

    test('auto detects FSK first', () {
      const eng = StegoEngine();
      final out = eng.embed(mode: StegoMode.overTheAir, text: 'AutoFSK');
      expect(eng.extract(out.stego), 'AutoFSK');
    });
  });
}
