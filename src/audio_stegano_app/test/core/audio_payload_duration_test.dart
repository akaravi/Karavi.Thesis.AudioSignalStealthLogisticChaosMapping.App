import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_stegano_app/core/audio/sample_rate_reconcile.dart';
import 'package:audio_stegano_app/core/audio/wav_io.dart';
import 'package:audio_stegano_app/core/stego/payload_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

Int16List _tone({
  required int sampleRate,
  required double seconds,
  double hz = 440,
  int amplitude = 8000,
}) {
  final n = (sampleRate * seconds).round();
  final out = Int16List(n);
  for (var i = 0; i < n; i++) {
    out[i] = (math.sin(2 * math.pi * hz * i / sampleRate) * amplitude)
        .round()
        .clamp(-32768, 32767);
  }
  return out;
}

void main() {
  group('SampleRateReconcile', () {
    test('retags 8 kHz capture wrongly labeled as 44100', () {
      final pcm = _tone(sampleRate: 8000, seconds: 2);
      final wrong = WavFile(
        sampleRate: 44100,
        numChannels: 1,
        bitsPerSample: 16,
        samples: pcm,
      );
      final fixed = SampleRateReconcile.reconcile(
        wrong,
        const Duration(seconds: 2),
      );
      expect(fixed.sampleRate, 8000);
    });

    test('leaves correct label unchanged', () {
      final pcm = _tone(sampleRate: 8000, seconds: 2);
      final ok = WavFile(
        sampleRate: 8000,
        numChannels: 1,
        bitsPerSample: 16,
        samples: pcm,
      );
      final fixed = SampleRateReconcile.reconcile(
        ok,
        const Duration(seconds: 2),
      );
      expect(fixed.sampleRate, 8000);
    });
  });

  group('Audio payload duration (pre-deploy gate)', () {
    test('wrong label 44100 on 8k capture → encode makes speech too fast', () {
      final pcm = _tone(sampleRate: 8000, seconds: 2);
      final wrong = WavFile(
        sampleRate: 44100,
        numChannels: 1,
        bitsPerSample: 16,
        samples: pcm,
      );
      final recovered = PayloadEnvelope.decodeAudioBody(
        PayloadEnvelope.encodeAudioBody(wrong),
      );
      final dur = SampleRateReconcile.durationSeconds(recovered);
      // Documents the historical bug: ~2s becomes ~0.36s (~5.5× fast).
      expect(dur, lessThan(0.6));
    });

    test('correct 8 kHz label preserves ~2s after encode/decode', () {
      final pcm = _tone(sampleRate: 8000, seconds: 2);
      final wav = WavFile(
        sampleRate: 8000,
        numChannels: 1,
        bitsPerSample: 16,
        samples: pcm,
      );
      final recovered = PayloadEnvelope.decodeAudioBody(
        PayloadEnvelope.encodeAudioBody(wav),
      );
      final dur = SampleRateReconcile.durationSeconds(recovered);
      expect(dur, closeTo(2.0, 0.05));
    });

    test('reconcile then encode preserves wall-clock duration', () {
      final pcm = _tone(sampleRate: 8000, seconds: 2);
      final wrong = WavFile(
        sampleRate: 44100,
        numChannels: 1,
        bitsPerSample: 16,
        samples: pcm,
      );
      final fixed = SampleRateReconcile.reconcile(
        wrong,
        const Duration(seconds: 2),
      );
      final recovered = PayloadEnvelope.decodeAudioBody(
        PayloadEnvelope.encodeAudioBody(fixed),
      );
      expect(
        SampleRateReconcile.durationSeconds(recovered),
        closeTo(2.0, 0.05),
      );
    });

    test('prepareAudioForExport preserves duration (±2%)', () {
      final pcm = _tone(sampleRate: 8000, seconds: 1.5);
      final wav = WavFile(
        sampleRate: 8000,
        numChannels: 1,
        bitsPerSample: 16,
        samples: pcm,
      );
      final body = PayloadEnvelope.decodeAudioBody(
        PayloadEnvelope.encodeAudioBody(wav),
      );
      final exported = PayloadEnvelope.prepareAudioForExport(body);
      expect(exported.sampleRate, PayloadAudioDefaults.exportSampleRate);
      expect(
        SampleRateReconcile.durationSeconds(exported),
        closeTo(1.5, 0.04),
      );
    });
  });
}
