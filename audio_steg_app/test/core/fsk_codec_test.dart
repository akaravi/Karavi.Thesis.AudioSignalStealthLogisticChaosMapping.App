import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_steg_app/core/stego/stego.dart';
import 'package:flutter_test/flutter_test.dart';

Float64List _addNoise(Float64List signal, double snrDb, {int seed = 1}) {
  final rng = math.Random(seed);
  var power = 0.0;
  for (final v in signal) {
    power += v * v;
  }
  power /= signal.length;
  final noisePower = power / math.pow(10, snrDb / 10);
  final sigma = math.sqrt(noisePower);
  final out = Float64List(signal.length);
  for (var i = 0; i < signal.length; i++) {
    final u1 = math.max(rng.nextDouble(), 1e-12);
    final u2 = rng.nextDouble();
    final z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    out[i] = signal[i] + sigma * z;
  }
  return out;
}

Float64List _padSilence(Float64List signal, int leadMs, int trailMs) {
  final lead = (leadMs * FskCodec.sampleRate / 1000).round();
  final trail = (trailMs * FskCodec.sampleRate / 1000).round();
  final out = Float64List(lead + signal.length + trail);
  out.setAll(lead, signal);
  return out;
}

void main() {
  group('FskCodec basic', () {
    test('clean round-trip ASCII', () {
      const codec = FskCodec();
      final s = codec.modulate('Hello FSK');
      final padded = _padSilence(s, 50, 50);
      expect(codec.demodulate(padded), 'Hello FSK');
    });

    test('clean round-trip Persian UTF-8', () {
      const codec = FskCodec();
      const msg = 'پیام FSK';
      final s = codec.modulate(msg);
      final padded = _padSilence(s, 50, 50);
      expect(codec.demodulate(padded), msg);
    });
  });

  group('FskCodec with noise', () {
    test('survives 20 dB AWGN', () {
      const codec = FskCodec();
      final s = codec.modulate('NoiseTest');
      final padded = _padSilence(s, 30, 30);
      final noisy = _addNoise(padded, 20);
      expect(codec.demodulate(noisy), 'NoiseTest');
    });

    test('survives 10 dB AWGN', () {
      const codec = FskCodec();
      final s = codec.modulate('Hi');
      final padded = _padSilence(s, 30, 30);
      final noisy = _addNoise(padded, 10);
      expect(codec.demodulate(noisy), 'Hi');
    });
  });

  group('FskCodec security', () {
    test('wrong key fails CRC -> returns null', () {
      const enc = FskCodec(x0: 0.45);
      const dec = FskCodec(x0: 0.46);
      final s = enc.modulate('Secret');
      final padded = _padSilence(s, 30, 30);
      expect(dec.demodulate(padded), isNull);
    });
  });
}
