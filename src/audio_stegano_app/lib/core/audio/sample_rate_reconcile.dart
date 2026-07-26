import 'dart:typed_data';

import 'wav_io.dart';

/// Corrects a mis-labeled PCM [WavFile] using wall-clock capture duration.
///
/// Example bug: capture at 8 kHz but WAV header stamped 44100 → encode
/// downsamples and recovered speech plays ~5.5× too fast.
abstract final class SampleRateReconcile {
  static const List<int> commonRates = [
    8000,
    11025,
    16000,
    22050,
    32000,
    44100,
    48000,
  ];

  /// Relative error above which the labeled rate is treated as wrong.
  static const double mismatchRatio = 0.15;

  /// Returns [wav] unchanged when [wallClock] is too short or label matches
  /// implied rate; otherwise retags to the nearest common rate.
  static WavFile reconcile(WavFile wav, Duration? wallClock) {
    if (wallClock == null || wallClock.inMilliseconds < 250) {
      return wav;
    }
    if (wav.samples.isEmpty) return wav;

    final implied =
        wav.samples.length * 1000.0 / wallClock.inMilliseconds;
    if (implied < 1000) return wav;

    final labeledErr = (implied - wav.sampleRate).abs() / implied;
    if (labeledErr <= mismatchRatio) {
      return wav;
    }

    var best = commonRates.first;
    var bestErr = (implied - best).abs();
    for (final rate in commonRates) {
      final err = (implied - rate).abs();
      if (err < bestErr) {
        bestErr = err;
        best = rate;
      }
    }

    if (best == wav.sampleRate) return wav;

    return WavFile(
      sampleRate: best,
      numChannels: wav.numChannels,
      bitsPerSample: wav.bitsPerSample,
      samples: Int16List.fromList(wav.samples),
    );
  }

  /// Duration in seconds from frame count / rate.
  static double durationSeconds(WavFile wav) {
    if (wav.sampleRate <= 0 || wav.samples.isEmpty) return 0;
    final ch = wav.numChannels < 1 ? 1 : wav.numChannels;
    final frames = wav.samples.length ~/ ch;
    return frames / wav.sampleRate;
  }
}
