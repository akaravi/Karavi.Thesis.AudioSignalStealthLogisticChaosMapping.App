import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart' as rec;

import 'wav_io.dart';

/// Internal state of [AudioRecorderService].
enum RecorderState { idle, starting, recording, stopping, disposed }

/// Cross-platform microphone recorder producing 16-bit PCM mono [WavFile].
///
/// ## Why we never call `recorder.stop()` / `recorder.dispose()`
///
/// `record_windows 1.0.7` (the only Windows implementation of `record`) has a
/// **use-after-free** in `Recorder::EndRecording()`:
///
/// ```cpp
/// SafeRelease(m_pReader);          // <- released here
/// if (m_pSource) m_pSource->Stop();
/// ...
/// ```
///
/// `m_pReader` is the `IMFSourceReaderCallback` instance that Media Foundation
/// calls back into on a worker thread (`OnReadSample`). Releasing it without
/// first signalling MF to stop can race with an in-flight callback, causing a
/// native access violation that terminates the entire Flutter process — no
/// Dart `try/catch`, `runZonedGuarded`, or `FlutterError.onError` can catch
/// it because the OS kills the process before any handler runs.
///
/// Mitigation strategy:
///   * Each recording session gets a fresh [rec.AudioRecorder] instance.
///   * On stop, we simply drop the Dart-side references and cancel the
///     [Stream] subscription (which only unregisters an `EventChannel`
///     listener — safe). The native capture session keeps running for the
///     remaining process lifetime (a few MB of leak per session) but never
///     reaches the buggy `EndRecording()` path.
///   * On all other platforms (Android/iOS/macOS/Linux/Web) the underlying
///     `record` plugins do not have this bug, but the same code path works
///     fine for them too — start/stop is symmetric per session.
///
/// Async safety guarantees:
///   * All public mutating operations run under an internal mutex
///     ([_runExclusive]) so two concurrent `start`/`stop`/`cancel` calls
///     cannot interleave.
///   * Public state is observable through [state] (synchronous) and
///     [stateStream] (broadcast).
class AudioRecorderService {
  AudioRecorderService();

  rec.AudioRecorder? _active;
  final StreamController<RecorderState> _stateController =
      StreamController<RecorderState>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  RecorderState _state = RecorderState.idle;
  int _sampleRate = 44100;
  int _numChannels = 1;

  StreamSubscription<Uint8List>? _streamSub;
  final BytesBuilder _buffer = BytesBuilder(copy: false);

  Completer<void>? _opLock;

  RecorderState get state => _state;
  Stream<RecorderState> get stateStream => _stateController.stream;
  bool get isRecording => _state == RecorderState.recording;
  bool get isBusy =>
      _state == RecorderState.starting ||
      _state == RecorderState.recording ||
      _state == RecorderState.stopping;
  int get currentSampleRate => _sampleRate;

  Future<bool> ensurePermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return false;
    }
    final probe = _active ?? rec.AudioRecorder();
    final ok = await probe.hasPermission();
    if (probe != _active) {
      // Discard the probe instance — we never call dispose() (see class docs).
    }
    return ok;
  }

  /// Starts a new streaming session.
  Future<void> start({int sampleRate = 44100}) async {
    return _runExclusive(() async {
      _ensureNotDisposed();
      if (_state != RecorderState.idle) {
        throw StateError(
          'Recorder is busy (state=$_state). Stop or cancel first.',
        );
      }
      _setState(RecorderState.starting);
      try {
        if (!await ensurePermission()) {
          throw StateError('Microphone permission denied.');
        }
        _sampleRate = sampleRate;
        _numChannels = 1;
        _buffer.clear();

        final newRecorder = rec.AudioRecorder();
        final config = rec.RecordConfig(
          encoder: rec.AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        );
        final stream = await newRecorder.startStream(config);

        _active = newRecorder;
        _streamSub = stream.listen(
          _onChunk,
          onError: (Object e, StackTrace st) {
            debugPrint('AudioRecorderService stream error: $e');
            unawaited(_safeRollbackTo(RecorderState.idle));
          },
          onDone: () {},
          cancelOnError: true,
        );

        _setState(RecorderState.recording);
      } catch (_) {
        await _safeRollbackTo(RecorderState.idle);
        rethrow;
      }
    });
  }

  /// Stops the active recording and returns the assembled [WavFile].
  Future<WavFile?> stopAndRead() async {
    return _runExclusive<WavFile?>(() async {
      _ensureNotDisposed();
      if (_state != RecorderState.recording) return null;

      // Take ownership of refs atomically.
      final sub = _streamSub;
      _streamSub = null;
      final old = _active;
      _active = null;

      // Snapshot the captured bytes BEFORE anything else that might fail.
      final bytes = _buffer.toBytes();
      _buffer.clear();

      // Move state to idle BEFORE any teardown so the UI cannot get stuck.
      _setState(RecorderState.idle);

      // Drop the subscription. cancel() only unregisters an EventChannel
      // listener on the Dart side, which is safe — but we still fire it
      // forget-and-forget so the UI thread is never blocked here.
      if (sub != null) {
        unawaited(
          sub.cancel().catchError((Object e) {
            debugPrint('AudioRecorderService cancel sub: $e');
          }),
        );
      }

      // CRITICAL: never call old.stop() / old.dispose() — see class docs.
      // We deliberately leak the underlying capture session for the
      // remainder of process lifetime (a few MB) in exchange for a
      // never-crashing UX. Suppress the unused-local lint.
      // ignore: unused_local_variable
      final _ = old;

      if (bytes.isEmpty) return null;
      final samples = _bytesToInt16Le(bytes);
      if (samples.isEmpty) return null;
      return WavFile(
        sampleRate: _sampleRate,
        numChannels: _numChannels,
        bitsPerSample: 16,
        samples: samples,
      );
    });
  }

  /// Cancels (and discards) the active recording.
  Future<void> cancel() async {
    return _runExclusive(() async {
      if (_state == RecorderState.disposed) return;
      if (_state == RecorderState.idle) return;
      final sub = _streamSub;
      _streamSub = null;
      _active = null;
      if (sub != null) {
        unawaited(
          sub.cancel().catchError((Object e) {
            debugPrint('AudioRecorderService cancel sub: $e');
          }),
        );
      }
      _buffer.clear();
      _setState(RecorderState.idle);
    });
  }

  /// Real-time RMS-based amplitude estimate in dBFS (≈ -90..0).
  Stream<double> amplitudeStream({Duration? interval}) {
    return _amplitudeController.stream;
  }

  Future<void> dispose() async {
    if (_state == RecorderState.disposed) return;
    if (_state != RecorderState.idle) {
      try {
        await cancel();
      } catch (_) {}
    }
    _setState(RecorderState.disposed);
    await _stateController.close();
    await _amplitudeController.close();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _onChunk(Uint8List chunk) {
    if (_state != RecorderState.recording) return;
    _buffer.add(chunk);
    if (!_amplitudeController.isClosed) {
      _amplitudeController.add(_estimateDbfs(chunk));
    }
  }

  double _estimateDbfs(Uint8List chunk) {
    if (chunk.length < 2) return -90.0;
    final n = chunk.length ~/ 2;
    var sumSq = 0.0;
    final bd = ByteData.sublistView(chunk);
    for (var i = 0; i < n; i++) {
      final s = bd.getInt16(i * 2, Endian.little) / 32768.0;
      sumSq += s * s;
    }
    final meanSq = sumSq / n;
    if (meanSq <= 1e-12) return -90.0;
    final db = 10 * (math.log(meanSq) / math.ln10);
    if (db.isNaN || db < -90) return -90.0;
    return db;
  }

  Int16List _bytesToInt16Le(Uint8List bytes) {
    final n = bytes.length ~/ 2;
    final out = Int16List(n);
    final bd = ByteData.sublistView(bytes);
    for (var i = 0; i < n; i++) {
      out[i] = bd.getInt16(i * 2, Endian.little);
    }
    return out;
  }

  Future<T> _runExclusive<T>(Future<T> Function() body) async {
    while (_opLock != null) {
      try {
        await _opLock!.future;
      } catch (_) {}
    }
    final lock = Completer<void>();
    _opLock = lock;
    try {
      return await body();
    } finally {
      _opLock = null;
      if (!lock.isCompleted) lock.complete();
    }
  }

  void _ensureNotDisposed() {
    if (_state == RecorderState.disposed) {
      throw StateError('AudioRecorderService is disposed.');
    }
  }

  void _setState(RecorderState s) {
    if (_state == s) return;
    _state = s;
    if (!_stateController.isClosed) {
      _stateController.add(s);
    }
  }

  Future<void> _safeRollbackTo(RecorderState target) async {
    final sub = _streamSub;
    _streamSub = null;
    _active = null;
    if (sub != null) {
      unawaited(
        sub.cancel().catchError((Object e) {
          debugPrint('AudioRecorderService rollback cancel: $e');
        }),
      );
    }
    _buffer.clear();
    _setState(target);
  }
}
