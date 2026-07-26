/// Minimum cover-recording budget so LSB capacity ≥ [requiredBits]
/// (one bit per mono sample, same as [EmbedMessage] capacity).
///
/// Prefer [samplesSatisfied] / [progressFromSamples] — wall-clock alone is
/// unreliable on web (undersampled streams vs nominal [coverSampleRate]).
class CoverRecordBudget {
  CoverRecordBudget._();

  static const int coverSampleRate = 44100;

  /// Extra mono samples beyond the bit budget (≈100 ms at 44.1 kHz).
  static const int safetySampleMargin = 4410;

  static int requiredSamples(int requiredBits) {
    if (requiredBits <= 0) return 0;
    return requiredBits + safetySampleMargin;
  }

  /// Wall-clock estimate with safety factor (UI hint only — not the stop gate).
  static Duration minDuration({
    required int requiredBits,
    int sampleRate = coverSampleRate,
    double safetyFactor = 1.35,
  }) {
    if (requiredBits <= 0 || sampleRate <= 0) {
      return Duration.zero;
    }
    final samples = requiredSamples(requiredBits);
    final micros =
        ((samples * safetyFactor * 1000000) / sampleRate).ceil();
    return Duration(microseconds: micros);
  }

  static double progressFromSamples(int bufferedSamples, int requiredBits) {
    final need = requiredSamples(requiredBits);
    if (need <= 0) return 1;
    final p = bufferedSamples / need;
    if (p.isNaN || p.isInfinite) return 0;
    return p.clamp(0.0, 1.0);
  }

  static bool samplesSatisfied(int bufferedSamples, int requiredBits) =>
      bufferedSamples >= requiredSamples(requiredBits);

  /// Remaining wall-clock estimate from missing samples at [sampleRate].
  static Duration remainingFromSamples({
    required int bufferedSamples,
    required int requiredBits,
    int sampleRate = coverSampleRate,
  }) {
    final need = requiredSamples(requiredBits) - bufferedSamples;
    if (need <= 0 || sampleRate <= 0) return Duration.zero;
    final micros = ((need * 1000000) / sampleRate).ceil();
    return Duration(microseconds: micros);
  }

  @Deprecated('Use progressFromSamples')
  static double progress(Duration elapsed, Duration min) {
    if (min <= Duration.zero) return 1;
    final p = elapsed.inMicroseconds / min.inMicroseconds;
    if (p.isNaN || p.isInfinite) return 0;
    return p.clamp(0.0, 1.0);
  }

  @Deprecated('Use samplesSatisfied')
  static bool isSatisfied(Duration elapsed, Duration min) =>
      min <= Duration.zero || elapsed >= min;
}
