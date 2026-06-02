import 'dart:typed_data';

import 'stego_common.dart';

/// `pipeline/logistic_map_keygen.m`
class LogisticMap {
  static const double defaultR = kWatermarkDefaultR;
  static const double defaultX0 = kWatermarkDefaultX0;

  static Float64List sequence({
    required int length,
    double x0 = defaultX0,
    double r = defaultR,
  }) {
    if (length <= 0) return Float64List(0);
    if (x0 <= 0.0 || x0 >= 1.0) {
      throw ArgumentError('x0 must be in (0,1), got $x0');
    }
    if (r <= 0.0 || r > 4.0) {
      throw ArgumentError('r must be in (0,4], got $r');
    }
    final out = Float64List(length);
    out[0] = r * x0 * (1.0 - x0);
    for (var i = 1; i < length; i++) {
      final prev = out[i - 1];
      out[i] = r * prev * (1.0 - prev);
    }
    return out;
  }

  static Uint8List binaryKey({
    required int length,
    double x0 = defaultX0,
    double r = defaultR,
  }) {
    final seq = sequence(length: length, x0: x0, r: r);
    if (seq.isEmpty) return Uint8List(0);
    var sum = 0.0;
    for (final v in seq) {
      sum += v;
    }
    final threshold = sum / seq.length;
    final key = Uint8List(length);
    for (var i = 0; i < length; i++) {
      key[i] = seq[i] >= threshold ? 1 : 0;
    }
    return key;
  }
}
