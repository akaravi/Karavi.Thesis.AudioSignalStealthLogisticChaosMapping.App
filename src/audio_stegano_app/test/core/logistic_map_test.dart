import 'package:audio_stegano_app/core/stego/stego.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogisticMap.sequence', () {
    test('first sample matches MATLAB formula r * x0 * (1 - x0)', () {
      final seq = LogisticMap.sequence(length: 1, x0: 0.45, r: 3.99);
      expect(seq[0], closeTo(3.99 * 0.45 * (1 - 0.45), 1e-12));
    });

    test('sequence is deterministic for same seed', () {
      final a = LogisticMap.sequence(length: 200, x0: 0.45, r: 3.99);
      final b = LogisticMap.sequence(length: 200, x0: 0.45, r: 3.99);
      for (var i = 0; i < a.length; i++) {
        expect(a[i], a[i]);
        expect(a[i], b[i]);
      }
    });

    test('tiny perturbation in x0 produces strongly different sequences', () {
      final a = LogisticMap.sequence(length: 1000, x0: 0.45, r: 3.99);
      final b = LogisticMap.sequence(length: 1000, x0: 0.45 + 1e-10, r: 3.99);
      var diffs = 0;
      for (var i = 0; i < a.length; i++) {
        if ((a[i] - b[i]).abs() > 1e-3) diffs++;
      }
      expect(diffs > 500, isTrue,
          reason: 'Chaotic divergence expected, got $diffs differences');
    });

    test('all values stay in [0,1]', () {
      final seq = LogisticMap.sequence(length: 10000, x0: 0.45, r: 3.99);
      for (final v in seq) {
        expect(v >= 0.0 && v <= 1.0, isTrue);
      }
    });
  });

  group('LogisticMap.binaryKey', () {
    test('returns 0/1 bytes only', () {
      final key = LogisticMap.binaryKey(length: 5000, x0: 0.45, r: 3.99);
      for (final b in key) {
        expect(b == 0 || b == 1, isTrue);
      }
    });

    test('bit balance close to 50% for chaotic regime', () {
      final key = LogisticMap.binaryKey(length: 10000, x0: 0.45, r: 3.99);
      final ones = key.where((b) => b == 1).length;
      final ratio = ones / key.length;
      expect(ratio, greaterThan(0.40));
      expect(ratio, lessThan(0.60));
    });

    test('NPCR-like: tiny key change flips ~50% of bits', () {
      final a = LogisticMap.binaryKey(length: 5000, x0: 0.45, r: 3.99);
      final b =
          LogisticMap.binaryKey(length: 5000, x0: 0.45 + 1e-10, r: 3.99);
      var flipped = 0;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) flipped++;
      }
      final ratio = flipped / a.length;
      expect(ratio, greaterThan(0.30),
          reason: 'Should flip ~50% of bits (got ${ratio * 100}%)');
    });

    test('rejects invalid x0/r', () {
      expect(() => LogisticMap.binaryKey(length: 10, x0: 0.0),
          throwsArgumentError);
      expect(() => LogisticMap.binaryKey(length: 10, x0: 1.0),
          throwsArgumentError);
      expect(() => LogisticMap.binaryKey(length: 10, r: 0.0),
          throwsArgumentError);
      expect(() => LogisticMap.binaryKey(length: 10, r: 5.0),
          throwsArgumentError);
    });

    test('zero length returns empty', () {
      expect(LogisticMap.binaryKey(length: 0).length, 0);
    });
  });
}
