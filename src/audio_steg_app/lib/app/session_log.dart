import 'dart:io';

import 'package:flutter/foundation.dart';

/// Writes session diagnostics to [logs/flutter_session.log] (project root).
abstract final class SessionLog {
  static File? _file;

  static Future<void> init() async {
    try {
      final dir = Directory('logs');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _file = File('logs/flutter_session.log');
      await _file!.writeAsString(
        '--- session ${DateTime.now().toIso8601String()} ---\n',
        flush: true,
      );
    } catch (e, st) {
      debugPrint('SessionLog.init failed: $e\n$st');
    }
  }

  static void write(String message, {Object? error, StackTrace? stack}) {
    final ts = DateTime.now().toIso8601String();
    final buffer = StringBuffer('[$ts] $message');
    if (error != null) {
      buffer.writeln();
      buffer.write('  error: $error');
    }
    if (stack != null) {
      buffer.writeln();
      buffer.write(stack);
    }
    final line = '${buffer.toString()}\n';
    debugPrint(line.trimRight());
    try {
      _file?.writeAsStringSync(line, mode: FileMode.append, flush: true);
    } catch (_) {
      // ignore file I/O failures
    }
  }
}
