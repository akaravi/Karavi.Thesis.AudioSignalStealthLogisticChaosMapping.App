import 'dart:math' as math;

import 'logistic_map_keygen.dart';

/// `train/logistic_positions.m`
class LogisticPositions {
  static List<int> compute({
    required int n,
    required int maxPos,
    double x0 = LogisticMap.defaultX0,
    double r = LogisticMap.defaultR,
  }) {
    if (n <= 0) return [];
    if (maxPos <= 0) {
      throw ArgumentError('maxPos must be positive, got $maxPos');
    }
    if (n > maxPos) {
      throw ArgumentError(
        'Need $n distinct positions but signal has only $maxPos samples.',
      );
    }
    if (x0 <= 0.0 || x0 >= 1.0) {
      throw ArgumentError('x0 must be in (0,1), got $x0');
    }
    if (r <= 0.0 || r > 4.0) {
      throw ArgumentError('r must be in (0,4], got $r');
    }

    final raw = List<int>.filled(n, 0);
    var x = x0;
    for (var i = 0; i < n; i++) {
      x = r * x * (1.0 - x);
      final matlabIdx = math.max(1, (x * maxPos).floor());
      raw[i] = matlabIdx - 1;
    }

    final unique = raw.toSet().toList()..sort();
    if (unique.length < n) {
      final used = unique.toSet();
      for (var i = 0; i < maxPos && unique.length < n; i++) {
        if (used.add(i)) unique.add(i);
      }
    }
    unique.sort();
    return unique.sublist(0, n);
  }
}
