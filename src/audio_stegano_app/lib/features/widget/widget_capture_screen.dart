import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config_provider.dart';
import '../../app/app_strings.dart';
import '../../app/session_log.dart';
import '../../app/settings_controller.dart';
import '../../core/audio/audio_input_loader.dart';
import '../../core/audio/audio_load_errors.dart';
import '../../core/audio/audio_recorder.dart';
import '../../core/audio/spectrum_analyzer.dart';
import '../../core/audio/stego_file_naming.dart';
import '../../core/audio/wav_io.dart';
import '../../core/platform/android_widget_action.dart';
import '../../core/stego/stego.dart';
import '../shared/audio_equalizer_view.dart';
import '../shared/circle_action_button.dart';
import '../shared/directional_text_field.dart';
import '../shared/embed_warning_dialog.dart';
import '../shared/message_bit_length_formatter.dart';
import '../shared/record_button.dart';
import '../shared/stego_share.dart';

/// Compact capture UI opened directly from the Android home-screen widget.
class WidgetCaptureScreen extends ConsumerStatefulWidget {
  const WidgetCaptureScreen({
    super.key,
    required this.initialAction,
  });

  final AndroidWidgetQuickAction initialAction;

  @override
  ConsumerState<WidgetCaptureScreen> createState() => _WidgetCaptureScreenState();
}

class _WidgetCaptureScreenState extends ConsumerState<WidgetCaptureScreen> {
  final _textCtrl = TextEditingController();
  final _textFocus = FocusNode();
  final AudioRecorderService _recorder = AudioRecorderService();

  bool _busy = false;
  bool _processing = false;
  String? _statusMessage;
  List<double> _eqBands = List<double>.filled(kSpectrumBandCount, 0);
  StreamSubscription<List<double>>? _spectrumSub;
  StreamSubscription<RecorderState>? _stateSub;
  DateTime? _recordStartedAt;
  Timer? _recordTickTimer;

  @override
  void initState() {
    super.initState();
    _stateSub = _recorder.stateStream.listen((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _textFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _recordTickTimer?.cancel();
    _stateSub?.cancel();
    _spectrumSub?.cancel();
    unawaited(_recorder.dispose());
    _textCtrl.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _close() => SystemNavigator.pop();

  Duration? get _recordingElapsed {
    final start = _recordStartedAt;
    if (start == null || !_recorder.isRecording) return null;
    return DateTime.now().difference(start);
  }

  Future<void> _toggleRecord() async {
    if (_busy || _processing) return;
    if (_recorder.isRecording) {
      await _stopAndEmbed();
      return;
    }
    final s = AppStrings.of(context);
    if (_textCtrl.text.trim().isEmpty) {
      await showEmbedWarningDialog(context, s.errorEmpty);
      _textFocus.requestFocus();
      return;
    }
    _busy = true;
    try {
      SessionLog.write('Widget capture: record start');
      await _recorder.start(sampleRate: 44100);
    } catch (e, st) {
      SessionLog.write('Widget capture: record start failed', error: e, stack: st);
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    _eqBands = List<double>.filled(kSpectrumBandCount, 0);
    _spectrumSub?.cancel();
    _spectrumSub = _recorder.spectrumStream.listen((bands) {
      if (!mounted) return;
      setState(() => _eqBands = List<double>.from(bands));
    });
    _recordStartedAt = DateTime.now();
    _recordTickTimer?.cancel();
    _recordTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_recorder.isRecording) return;
      setState(() {});
    });
    setState(() => _statusMessage = s.recording);
  }

  Future<void> _stopAndEmbed() async {
    final s = AppStrings.of(context);
    setState(() {
      _processing = true;
      _statusMessage = s.processing;
    });
    _recordTickTimer?.cancel();
    _recordStartedAt = null;
    await _spectrumSub?.cancel();
    _spectrumSub = null;

    WavFile? cover;
    try {
      cover = await _recorder.stopAndRead();
    } catch (e, st) {
      SessionLog.write('Widget capture: record stop failed', error: e, stack: st);
      if (!mounted) return;
      setState(() {
        _processing = false;
        _statusMessage = e.toString();
      });
      return;
    }
    if (!mounted || cover == null) {
      setState(() {
        _processing = false;
        _statusMessage = 'No recorded audio.';
      });
      return;
    }
    await _embedCover(cover);
  }

  Future<void> _pickAndEmbed() async {
    if (_busy || _processing || _recorder.isRecording) return;
    final s = AppStrings.of(context);
    if (_textCtrl.text.trim().isEmpty) {
      await showEmbedWarningDialog(context, s.errorEmpty);
      _textFocus.requestFocus();
      return;
    }

    FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: AudioInputLoader.audioPickerExtensions,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
      return;
    }
    if (!mounted || picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    if (file.name.isEmpty) return;

    setState(() {
      _processing = true;
      _statusMessage = s.processing;
    });

    try {
      final cover = await AudioInputLoader.loadPickedFile(
        fileName: file.name,
        bytes: file.bytes,
        path: file.path,
      );
      if (!mounted) return;
      await _embedCover(cover);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _statusMessage = audioLoadErrorMessage(s, e);
      });
    }
  }

  Future<void> _embedCover(WavFile cover) async {
    final s = AppStrings.of(context);
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _processing = false);
      await showEmbedWarningDialog(context, s.errorEmpty);
      return;
    }

    final settings = ref.read(settingsProvider);
    final deploy = ref.read(appConfigProvider);
    final fixedBits = deploy.defaultFixedMessageBitLength;
    final useFixedLen = settings.defaultFixedMessageBitLimit;
    final required = useFixedLen
        ? fixedBits
        : MessageBits.bitLengthForText(text);
    final available = cover.toMono().samples.length;
    if (required > available ||
        (useFixedLen && MessageBits.bitLengthForText(text) > fixedBits)) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _statusMessage = null;
      });
      await showEmbedWarningDialog(context, s.errorTooLong);
      return;
    }

    EmbedRunResult? produced;
    String? error;
    try {
      produced = await StegoRunner.embed(
        text: text,
        cover: cover,
        r: settings.r,
        x0: settings.x0,
        fixedMsgBitLength: useFixedLen ? fixedBits : null,
      );
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    setState(() {
      _processing = false;
      _statusMessage = error;
    });

    if (error != null) {
      final lower = error.toLowerCase();
      if (lower.contains('too long')) {
        await showEmbedWarningDialog(context, s.errorTooLong);
      }
      return;
    }

    if (produced != null) {
      await _showSuccess(produced);
    }
  }

  Future<void> _showSuccess(EmbedRunResult result) async {
    if (!mounted) return;
    final s = AppStrings.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(s.widgetCaptureSuccessTitle),
          content: Text(
            s.widgetCaptureSuccessBody,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(s.widgetCaptureClose),
            ),
            FilledButton.icon(
              onPressed: () async {
                await shareStegoWavBytes(
                  bytes: result.stego.encode(),
                  fileName: stegoWavFileName(result.msgBitLength),
                  subject: s.shareStego,
                );
                if (!dialogCtx.mounted) return;
                Navigator.of(dialogCtx).pop();
                _close();
              },
              icon: const Icon(Icons.share_outlined),
              label: Text(s.shareStego),
            ),
          ],
        );
      },
    );
    if (mounted) _close();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final settings = ref.watch(settingsProvider);
    final deploy = ref.watch(appConfigProvider);
    final useFixedLimit = settings.defaultFixedMessageBitLimit;
    final fixedBits = deploy.defaultFixedMessageBitLength;
    final isRecording = _recorder.isRecording;
    final scheme = Theme.of(context).colorScheme;
    final recordMode = widget.initialAction == AndroidWidgetQuickAction.record;

    return PopScope(
      canPop: !isRecording && !_processing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (isRecording || _processing) return;
        _close();
      },
      child: Scaffold(
        backgroundColor: scheme.surface.withValues(alpha: 0.98),
        appBar: AppBar(
          title: Text(
            recordMode ? s.widgetCaptureRecordTitle : s.widgetCaptureEmbedTitle,
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: (isRecording || _processing) ? null : _close,
          ),
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DirectionalTextField(
                  controller: _textCtrl,
                  focusNode: _textFocus,
                  maxLines: 4,
                  minLines: 3,
                  enabled: !isRecording && !_processing,
                  inputFormatters: useFixedLimit
                      ? [MessageBitLengthFormatter(fixedBits)]
                      : const [],
                  decoration: InputDecoration(
                    labelText: s.textHint,
                    prefixIcon: const Icon(Icons.message_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                if (recordMode) ...[
                  AudioEqualizerView(
                    bands: _eqBands,
                    active: isRecording,
                    recordingElapsed: _recordingElapsed,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: RecordButton(
                      isActive: isRecording,
                      enabled: isRecording || (!_processing && !_busy),
                      onPressed: _toggleRecord,
                      labelIdle: s.startRecording,
                      labelActive: s.stopRecording,
                    ),
                  ),
                ] else ...[
                  Center(
                    child: CircleActionButton(
                      icon: Icons.upload_file_outlined,
                      label: s.loadAudioFile,
                      shape: ActionButtonShape.roundedSquare,
                      enabled: !_processing && !_busy && !isRecording,
                      onPressed: _pickAndEmbed,
                      accent: CircleActionAccent.primary,
                    ),
                  ),
                ],
                if (_processing) ...[
                  const SizedBox(height: 20),
                  const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ],
                if (_statusMessage != null && !_processing) ...[
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
