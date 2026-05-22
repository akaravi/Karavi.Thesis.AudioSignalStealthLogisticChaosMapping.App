import 'dart:io';

import 'package:flutter/foundation.dart';

Future<void> sessionLogInit() async {
  try {
    final dir = Directory('logs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('logs/flutter_session.log');
    await file.writeAsString(
      '--- session ${DateTime.now().toIso8601String()} ---\n',
      flush: true,
    );
    sessionLogSetFile(file);
  } catch (e, st) {
    debugPrint('SessionLog.init failed: $e\n$st');
  }
}

File? _sessionLogFile;

void sessionLogSetFile(File file) => _sessionLogFile = file;

void sessionLogWrite(String message, {Object? error, StackTrace? stack}) {
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
    _sessionLogFile?.writeAsStringSync(
      line,
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {
    // ignore file I/O failures
  }
}
