import 'dart:math' as math;
import 'dart:typed_data';

/// Audio steganography evaluation metrics — port of `Matlab/evaluate_stego.m`.
class StegoMetrics {
  final double snrDb;
  final double psnrDb;
  final double berPercent;

  const StegoMetrics({
    required this.snrDb,
    required this.psnrDb,
    required this.berPercent,
  });

  /// Compares cover vs stego (both as int16 PCM samples) plus the
  /// original/extracted bit streams.
  factory StegoMetrics.compute({
    required Int16List cover,
    required Int16List stego,
    required Uint8List originalBits,
    required Uint8List extractedBits,
  }) {
    final n = math.min(cover.length, stego.length);
    var signalPower = 0.0;
    var noisePower = 0.0;
    for (var i = 0; i < n; i++) {
      final c = cover[i] / 32768.0;
      final s = stego[i] / 32768.0;
      signalPower += c * c;
      final d = c - s;
      noisePower += d * d;
    }
    final snr = noisePower == 0
        ? double.infinity
        : 10 * (math.log(signalPower / noisePower) / math.ln10);
    final mse = noisePower / n;
    final psnr = mse == 0
        ? double.infinity
        : 10 * (math.log(1.0 / mse) / math.ln10);

    final m = math.min(originalBits.length, extractedBits.length);
    var errors = 0;
    for (var i = 0; i < m; i++) {
      if (originalBits[i] != extractedBits[i]) errors++;
    }
    final ber = m == 0 ? 0.0 : (errors / m) * 100.0;

    return StegoMetrics(snrDb: snr, psnrDb: psnr, berPercent: ber);
  }
}
