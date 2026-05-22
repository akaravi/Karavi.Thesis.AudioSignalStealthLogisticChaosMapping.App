import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// We can't easily unit-test [AudioRecorderService] without mocking the native
/// `record` plugin, so this test exercises the same exclusion primitive that
/// guards every public method on the service.
class _Mutex {
  Completer<void>? _lock;

  Future<T> run<T>(Future<T> Function() body) async {
    while (_lock != null) {
      try {
        await _lock!.future;
      } catch (_) {}
    }
    final c = Completer<void>();
    _lock = c;
    try {
      return await body();
    } finally {
      _lock = null;
      if (!c.isCompleted) c.complete();
    }
  }
}

void main() {
  group('Mutex semantics (the same primitive used in AudioRecorderService)', () {
    test('serializes concurrent invocations', () async {
      final m = _Mutex();
      final order = <String>[];
      Future<void> step(String name, int ms) => m.run(() async {
            order.add('$name:start');
            await Future<void>.delayed(Duration(milliseconds: ms));
            order.add('$name:end');
          });
      await Future.wait([step('A', 30), step('B', 5), step('C', 5)]);
      expect(order, [
        'A:start', 'A:end',
        'B:start', 'B:end',
        'C:start', 'C:end',
      ]);
    });

    test('releases the lock even when body throws', () async {
      final m = _Mutex();
      Object? caught;
      try {
        await m.run(() async {
          throw StateError('boom');
        });
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<StateError>());
      final ok = await m.run(() async => 42);
      expect(ok, 42);
    });

    test('does not deadlock when previous holder failed', () async {
      final m = _Mutex();
      final futures = <Future<int>>[];
      futures.add(m.run<int>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        throw Exception('fail-A');
      }).catchError((_) => -1));
      futures.add(m.run<int>(() async => 1));
      futures.add(m.run<int>(() async => 2));
      final results = await Future.wait(futures);
      expect(results, [-1, 1, 2]);
    });
  });
}
