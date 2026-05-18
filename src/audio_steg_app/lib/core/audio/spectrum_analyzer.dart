import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart';

import 'wav_io.dart';

/// Number of equalizer bars shown in the UI.
const int kSpectrumBandCount = 32;

/// FFT-based spectrum magnitudes normalized to [0, 1].
abstract final class SpectrumAnalyzer {
  static List<double> bandsFromPcm(
    Int16List samples, {
    int sampleRate = 44100,
    int bandCount = kSpectrumBandCount,
  }) {
    if (samples.isEmpty) {
      return List<double>.filled(bandCount, 0);
    }

    const fftSize = 1024;
    final windowed = Float64List(fftSize);
    final start = samples.length > fftSize ? samples.length - fftSize : 0;
    final count = samples.length - start;
    final denom = count > 1 ? count - 1 : 1;
    for (var i = 0; i < fftSize; i++) {
      if (i < count) {
        final hann = 0.5 - 0.5 * math.cos(2 * math.pi * i / denom);
        windowed[i] = (samples[start + i] / 32768.0) * hann;
      } else {
        windowed[i] = 0;
      }
    }

    final fft = FFT(fftSize);
    final spectrum = fft.realFft(windowed);
    final half = fftSize ~/ 2;
    final nyquist = sampleRate / 2.0;
    final minHz = 60.0;
    final maxHz = math.min(16000.0, nyquist);
    final logMin = math.log(minHz);
    final logMax = math.log(maxHz);

    final out = List<double>.filled(bandCount, 0);
    for (var b = 0; b < bandCount; b++) {
      final t0 = b / bandCount;
      final t1 = (b + 1) / bandCount;
      final f0 = math.exp(logMin + (logMax - logMin) * t0);
      final f1 = math.exp(logMin + (logMax - logMin) * t1);
      final i0 = (f0 / nyquist * half).floor().clamp(1, half - 1);
      final i1 = (f1 / nyquist * half).ceil().clamp(i0 + 1, half);
      var peak = 0.0;
      for (var i = i0; i < i1; i++) {
        final c = spectrum[i];
        final mag = math.sqrt(c.x * c.x + c.y * c.y);
        if (mag > peak) peak = mag;
      }
      final db = 20 * math.log(peak + 1e-9) / math.ln10;
      out[b] = ((db + 60) / 60).clamp(0.0, 1.0);
    }
    return out;
  }

  /// Timeline of spectrum frames for playback visualization (~20 fps).
  static List<List<double>> timelineFromWav(
    WavFile wav, {
    int frameMs = 50,
    int bandCount = kSpectrumBandCount,
  }) {
    final mono = wav.toMono();
    final samples = mono.samples;
    final rate = mono.sampleRate;
    if (samples.isEmpty) return [];

    final hop = math.max(256, rate * frameMs ~/ 1000);
    const win = 1024;
    final frames = <List<double>>[];
    for (var i = 0; i + win <= samples.length; i += hop) {
      frames.add(
        bandsFromPcm(
          samples.sublist(i, i + win),
          sampleRate: rate,
          bandCount: bandCount,
        ),
      );
    }
    if (frames.isEmpty && samples.length >= 256) {
      frames.add(bandsFromPcm(samples, sampleRate: rate, bandCount: bandCount));
    }
    return frames;
  }
}
