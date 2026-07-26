import 'dart:math' as math;
import 'dart:typed_data';

import 'wav_io.dart';

/// Downsamples mono PCM to peak envelopes in [0, 1] (vs full-scale int16).
List<double> waveformEnvelopeFromWav(WavFile wav, {int maxPoints = 512}) {
  final mono = wav.toMono().samples;
  return waveformEnvelopeFromPcm(mono, maxPoints: maxPoints);
}

List<double> waveformEnvelopeFromPcm(Int16List samples, {int maxPoints = 512}) {
  if (samples.isEmpty) return const [];
  if (samples.length <= maxPoints) {
    return samples.map((s) => s.abs() / 32768.0).toList();
  }
  final out = List<double>.filled(maxPoints, 0);
  final step = samples.length / maxPoints;
  for (var i = 0; i < maxPoints; i++) {
    final start = (i * step).floor();
    final end = math.min(((i + 1) * step).ceil(), samples.length);
    var peak = 0.0;
    for (var j = start; j < end; j++) {
      final v = samples[j].abs() / 32768.0;
      if (v > peak) peak = v;
    }
    out[i] = peak;
  }
  return out;
}

/// Max peak across one or more envelopes (full-scale units).
double waveformEnvelopePeak(Iterable<List<double>> series) {
  var peak = 0.0;
  for (final s in series) {
    for (final v in s) {
      if (v > peak) peak = v;
    }
  }
  return peak;
}

/// Rescale envelopes so the joint peak fills [targetPeak] of the chart (quiet
/// speech still reads clearly). Same scale for every series (fair compare).
List<List<double>> waveformNormalizeForDisplay(
  List<List<double>> series, {
  double targetPeak = 0.92,
  double minPeak = 1e-4,
}) {
  if (series.isEmpty) return series;
  final peak = waveformEnvelopePeak(series);
  if (peak < minPeak) return series;
  final gain = targetPeak / peak;
  return [
    for (final s in series)
      [for (final v in s) (v * gain).clamp(0.0, 1.0)],
  ];
}
