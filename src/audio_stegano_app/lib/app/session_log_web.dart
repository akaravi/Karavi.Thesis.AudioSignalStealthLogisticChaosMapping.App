import 'package:flutter/foundation.dart';

Future<void> sessionLogInit() async {}

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
  debugPrint(buffer.toString());
}
