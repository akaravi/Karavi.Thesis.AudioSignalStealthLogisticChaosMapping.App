import 'session_log_io.dart'
    if (dart.library.html) 'session_log_web.dart'
    as impl;

/// Session diagnostics (file on native; console on web).
abstract final class SessionLog {
  static Future<void> init() => impl.sessionLogInit();

  static void write(String message, {Object? error, StackTrace? stack}) {
    impl.sessionLogWrite(message, error: error, stack: stack);
  }
}
