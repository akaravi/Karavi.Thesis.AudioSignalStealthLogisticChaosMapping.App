import 'dart:math' as math;
import 'dart:typed_data';

import '../audio/wav_io.dart';

/// `evaluate_stego.m`
class WatermarkMetrics {
  final double snrDb;
  final double psnrDb;
  final double berPercent;
  final double npcrPercent;
  final double uaciPercent;

  const WatermarkMetrics({
    required this.snrDb,
    required this.psnrDb,
    required this.berPercent,
    required this.npcrPercent,
    required this.uaciPercent,
  });

  factory WatermarkMetrics.evaluate({
    required Int16List cover,
    required Int16List stego,
    required Uint8List originalBits,
    required Uint8List extractedBits,
    required Int16List stegoWithDiffKey,
  }) {
    final n = math.min(cover.length, stego.length);
    final x = Float64List(n);
    final y = Float64List(n);
    for (var i = 0; i < n; i++) {
      x[i] = cover[i] / 32767.0;
      y[i] = stego[i] / 32767.0;
    }

    var signalPower = 0.0;
    var noisePower = 0.0;
    for (var i = 0; i < n; i++) {
      signalPower += x[i] * x[i];
      final d = x[i] - y[i];
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
      if ((originalBits[i] & 1) != (extractedBits[i] & 1)) errors++;
    }
    final ber = m == 0 ? 0.0 : (errors / m) * 100.0;

    final len = math.min(n, stegoWithDiffKey.length);
    var diffCount = 0;
    var absSum = 0.0;
    for (var i = 0; i < len; i++) {
      final y1 = stego[i] / 32767.0;
      final y2 = stegoWithDiffKey[i] / 32767.0;
      if (y1 != y2) diffCount++;
      absSum += (y1 - y2).abs();
    }
    final npcr = len == 0 ? 0.0 : (diffCount / len) * 100.0;
    final uaci = len == 0 ? 0.0 : (absSum / (len * 2.0)) * 100.0;

    return WatermarkMetrics(
      snrDb: snr,
      psnrDb: psnr,
      berPercent: ber,
      npcrPercent: npcr,
      uaciPercent: uaci,
    );
  }
}

/// خروجی `embed_message.m`
class WatermarkEmbedResult {
  final WavFile stego;
  final Uint8List extractedBits;
  final int bitsEmbedded;
  final int capacityBits;

  const WatermarkEmbedResult({
    required this.stego,
    required this.extractedBits,
    required this.bitsEmbedded,
    required this.capacityBits,
  });

  Uint8List get extractedMsg => extractedBits;
}

/// خروجی کامل embed + ارزیابی
class WatermarkOutcome {
  final WavFile stego;
  final WatermarkMetrics metrics;
  final int bitsEmbedded;
  final int capacityBits;
  final Uint8List originalBits;
  final Uint8List extractedBits;

  const WatermarkOutcome({
    required this.stego,
    required this.metrics,
    required this.bitsEmbedded,
    required this.capacityBits,
    required this.originalBits,
    required this.extractedBits,
  });
}
