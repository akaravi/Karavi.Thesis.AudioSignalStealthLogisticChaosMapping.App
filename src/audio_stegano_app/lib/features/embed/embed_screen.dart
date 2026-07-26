import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/app_config_provider.dart';
import '../../app/app_strings.dart';
import '../../app/metric_help_strings.dart';
import '../../core/io/native_file.dart';
import '../../app/session_log.dart';
import '../../app/settings_controller.dart';
import '../../core/audio/audio_input_loader.dart';
import '../../core/audio/audio_load_errors.dart';
import '../../core/audio/audio_player.dart';
import '../../core/audio/audio_recorder.dart';
import '../../core/audio/sample_rate_reconcile.dart';
import '../../core/audio/stego_file_naming.dart';
import '../../core/audio/wav_io.dart';
import '../../core/audio/spectrum_analyzer.dart';
import '../../core/audio/waveform_display.dart';
import '../../core/stego/stego.dart';
import '../shared/audio_file_drop_surface.dart';
import '../shared/audio_equalizer_view.dart';
import '../shared/dual_waveform_chart.dart';
import '../shared/circle_action_button.dart';
import '../shared/directional_text_field.dart';
import '../shared/embed_metric_kind.dart';
import '../shared/help_sheet.dart';
import '../shared/embed_warning_dialog.dart';
import '../shared/metric_help_dialog.dart';
import '../shared/message_bit_length_formatter.dart';
import '../shared/record_button.dart';
import '../shared/stego_share.dart';
import '../shared/tab_scroll_body.dart';

enum _EmbedPayloadKind { text, audio, image }

class EmbedScreen extends ConsumerStatefulWidget {
  const EmbedScreen({super.key});

  @override
  ConsumerState<EmbedScreen> createState() => _EmbedScreenState();
}

class _EmbedScreenState extends ConsumerState<EmbedScreen> {
  final _textCtrl = TextEditingController();
  final _textFocus = FocusNode();
  final AudioRecorderService _recorder = AudioRecorderService();
  final AudioPlayerService _player = AudioPlayerService();

  bool _busy = false;
  bool _processing = false;
  bool _verifying = false;

  /// After a successful embed, message field and record/load card stay hidden until new embed.
  bool _embedInputHidden = false;
  _EmbedPayloadKind _payloadKind = _EmbedPayloadKind.text;
  WavFile? _payloadAudio;
  Uint8List? _payloadImageBytes;
  bool _recordingPayload = false;
  final GlobalKey _resultCardKey = GlobalKey();
  final ScrollController _scrollCtrl = ScrollController();
  WavFile? _cover;
  WavFile? _stego;
  EmbedRunResult? _result;
  String? _statusMessage;
  String? _verifyStatus;
  bool? _verifyOk;
  List<double> _eqBands = List<double>.filled(kSpectrumBandCount, 0);
  bool _isPlaying = false;
  bool _playbackLoaded = false;
  StreamSubscription<List<double>>? _spectrumSub;
  StreamSubscription<PlayerState>? _playStateSub;
  StreamSubscription<RecorderState>? _stateSub;
  DateTime? _recordStartedAt;
  Timer? _recordTickTimer;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _stateSub = _recorder.stateStream.listen((s) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _recordTickTimer?.cancel();
    _stateSub?.cancel();
    _cancelSpectrum();
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    _textCtrl.dispose();
    _textFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelSpectrum() async {
    final sub = _spectrumSub;
    _spectrumSub = null;
    if (sub != null) await sub.cancel();
    final playSub = _playStateSub;
    _playStateSub = null;
    if (playSub != null) await playSub.cancel();
  }

  void _attachPlaybackSpectrum() {
    _playStateSub?.cancel();
    _playStateSub = _player.stateStream.listen((st) {
      if (!mounted) return;
      final completed = st.processingState == ProcessingState.completed;
      setState(() {
        _isPlaying = completed ? false : st.playing;
        _playbackLoaded = _stego != null && (_player.hasSource || completed);
      });
      if (!st.playing) {
        setState(() => _eqBands = List<double>.filled(kSpectrumBandCount, 0));
      }
    });
    _spectrumSub?.cancel();
    _spectrumSub = _player.spectrumStream.listen((bands) {
      if (!mounted) return;
      setState(() => _eqBands = List<double>.from(bands));
    });
  }

  Future<void> _toggleRecord() async {
    if (_busy) return;
    if (_recorder.isRecording) {
      if (_recordingPayload) {
        await _stopPayloadRecording();
      } else {
        await _stopAndProcess();
      }
      return;
    }
    _busy = true;
    try {
      if (_payloadKind == _EmbedPayloadKind.audio && _payloadAudio == null) {
        await _startPayloadRecording();
      } else {
        await _startRecording();
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  int _settingsBitBudget() {
    final deploy = ref.read(appConfigProvider);
    return deploy.defaultFixedMessageBitLength;
  }

  Future<void> _startPayloadRecording() async {
    final s = AppStrings.of(context);
    try {
      SessionLog.write('Embed: payload record start');
      await _recorder.start(sampleRate: PayloadAudioDefaults.sampleRate);
    } catch (e, st) {
      SessionLog.write('Embed: payload record start failed', error: e, stack: st);
      if (!mounted) return;
      _showStatus(e.toString());
      return;
    }
    if (!mounted) return;
    _eqBands = List<double>.filled(kSpectrumBandCount, 0);
    final sub = _recorder.spectrumStream.listen((bands) {
      if (!mounted) return;
      setState(() => _eqBands = List<double>.from(bands));
    });
    _spectrumSub = sub;
    _recordStartedAt = DateTime.now();
    _recordTickTimer?.cancel();
    _recordTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_recorder.isRecording) return;
      final budget = _settingsBitBudget();
      final maxDur = PayloadAudioDefaults.maxDurationForBitBudget(budget);
      final elapsed = _recordingElapsed;
      if (elapsed != null && elapsed >= maxDur) {
        unawaited(_stopPayloadRecording());
        return;
      }
      setState(() {});
    });
    setState(() {
      _recordingPayload = true;
      _embedInputHidden = false;
      _cover = null;
      _stego = null;
      _result = null;
      _verifyStatus = null;
      _verifyOk = null;
      _statusMessage = s.recording;
    });
  }

  Future<void> _stopPayloadRecording() async {
    final s = AppStrings.of(context);
    if (mounted) {
      setState(() {
        _processing = true;
        _statusMessage = s.processing;
      });
    }
    try {
      await _cancelSpectrum();
      _clearRecordTimer();
      WavFile? raw;
      try {
        SessionLog.write('Embed: payload record stop');
        raw = await _recorder.stopAndRead();
      } catch (e, st) {
        SessionLog.write('Embed: payload record stop failed', error: e, stack: st);
        if (!mounted) return;
        setState(() {
          _processing = false;
          _recordingPayload = false;
          _statusMessage = e.toString();
        });
        return;
      }
      if (!mounted) return;
      if (raw == null || raw.samples.isEmpty) {
        setState(() {
          _processing = false;
          _recordingPayload = false;
          _statusMessage = 'No recorded audio.';
        });
        return;
      }
      final wallClock = _recordingElapsed;
      final reconciled = SampleRateReconcile.reconcile(raw, wallClock);
      final budget = _settingsBitBudget();
      final bitsNeeded = PayloadEnvelope.bitLengthForAudio(reconciled);
      final settings = ref.read(settingsProvider);
      final cap = settings.defaultFixedMessageBitLimit ? budget : budget;
      if (bitsNeeded > cap) {
        setState(() {
          _processing = false;
          _recordingPayload = false;
          _payloadAudio = null;
        });
        await _showEmbedWarning(s.errorPayloadAudioBudget);
        return;
      }
      setState(() {
        _processing = false;
        _recordingPayload = false;
        _payloadAudio = reconciled;
        _statusMessage = s.payloadAudioReady;
        _eqBands = List<double>.filled(kSpectrumBandCount, 0);
      });
    } finally {
      _releaseEmbedInteractionLocks();
    }
  }

  Future<void> _startRecording() async {
    final s = AppStrings.of(context);
    if (_payloadKind == _EmbedPayloadKind.text) {
      final text = _textCtrl.text.trim();
      if (text.isEmpty) {
        await _showEmbedWarning(s.errorEmpty);
        return;
      }
    } else if (_payloadKind == _EmbedPayloadKind.audio) {
      if (_payloadAudio == null) {
        await _showEmbedWarning(s.errorEmptyPayloadAudio);
        return;
      }
    } else if (_payloadImageBytes == null) {
      await _showEmbedWarning(s.errorEmptyPayloadImage);
      return;
    }
    try {
      SessionLog.write('Embed: cover record start');
      await _recorder.start(sampleRate: 44100);
    } catch (e, st) {
      SessionLog.write('Embed: record start failed', error: e, stack: st);
      if (!mounted) return;
      _showStatus(e.toString());
      return;
    }
    if (!mounted) return;
    _eqBands = List<double>.filled(kSpectrumBandCount, 0);
    final sub = _recorder.spectrumStream.listen((bands) {
      if (!mounted) return;
      setState(() => _eqBands = List<double>.from(bands));
    });
    _spectrumSub = sub;
    _recordStartedAt = DateTime.now();
    _recordTickTimer?.cancel();
    _recordTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_recorder.isRecording) return;
      setState(() {});
    });
    setState(() {
      _recordingPayload = false;
      _embedInputHidden = false;
      _cover = null;
      _stego = null;
      _result = null;
      _verifyStatus = null;
      _verifyOk = null;
      _statusMessage = s.recording;
    });
  }

  void _clearRecordTimer() {
    _recordTickTimer?.cancel();
    _recordTickTimer = null;
    _recordStartedAt = null;
  }

  Duration? get _recordingElapsed {
    final start = _recordStartedAt;
    if (start == null || !_recorder.isRecording) return null;
    return DateTime.now().difference(start);
  }

  Future<void> _stopAndProcess() async {
    final s = AppStrings.of(context);
    if (mounted) {
      setState(() {
        _processing = true;
        _statusMessage = s.processing;
      });
    }
    try {
      await _cancelSpectrum();
      _clearRecordTimer();

      WavFile? cover;
      try {
        SessionLog.write('Embed: record stop');
        cover = await _recorder.stopAndRead();
      } catch (e, st) {
        SessionLog.write('Embed: record stop failed', error: e, stack: st);
        if (!mounted) return;
        setState(() {
          _processing = false;
          _statusMessage = e.toString();
        });
        return;
      }
      if (!mounted) return;
      if (cover == null) {
        setState(() {
          _processing = false;
          _statusMessage = 'No recorded audio.';
        });
        return;
      }
      await _embedWithCover(cover);
    } finally {
      _releaseEmbedInteractionLocks();
    }
  }

  void _releaseEmbedInteractionLocks() {
    if (!mounted) return;
    setState(() {
      _processing = false;
      _busy = false;
    });
  }

  Future<void> _loadAndEmbed() async {
    if (_busy || _processing || _recorder.isRecording) return;
    final s = AppStrings.of(context);
    if (_payloadKind == _EmbedPayloadKind.text) {
      if (_textCtrl.text.trim().isEmpty) {
        await _showEmbedWarning(s.errorEmpty);
        return;
      }
    } else if (_payloadKind == _EmbedPayloadKind.audio) {
      if (_payloadAudio == null) {
        await _showEmbedWarning(s.errorEmptyPayloadAudio);
        return;
      }
    } else if (_payloadImageBytes == null) {
      await _showEmbedWarning(s.errorEmptyPayloadImage);
      return;
    }

    FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: AudioInputLoader.audioPickerExtensions,
        withData: kIsWeb,
      );
    } catch (e) {
      _showStatus(e.toString());
      return;
    }
    if (!mounted || picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final name = file.name;
    if (name.isEmpty) {
      _showStatus(s.pickFile);
      return;
    }

    await _loadAndEmbedPicked(
      fileName: name,
      bytes: file.bytes,
      path: kIsWeb ? null : file.path,
    );
  }

  Future<void> _embedFromDroppedPath(String filePath) async {
    if (_busy || _processing || _recorder.isRecording) return;
    final s = AppStrings.of(context);
    if (_payloadKind == _EmbedPayloadKind.text) {
      if (_textCtrl.text.trim().isEmpty) {
        await _showEmbedWarning(s.errorEmpty);
        return;
      }
    } else if (_payloadKind == _EmbedPayloadKind.audio) {
      if (_payloadAudio == null) {
        await _showEmbedWarning(s.errorEmptyPayloadAudio);
        return;
      }
    } else if (_payloadImageBytes == null) {
      await _showEmbedWarning(s.errorEmptyPayloadImage);
      return;
    }
    await _loadAndEmbedPicked(
      fileName: p.basename(filePath),
      path: filePath,
    );
  }

  Future<void> _loadAndEmbedPicked({
    required String fileName,
    Uint8List? bytes,
    String? path,
  }) async {
    if (!mounted) return;
    final s = AppStrings.of(context);

    _busy = true;
    setState(() {
      _processing = true;
      _statusMessage = s.processing;
    });

    try {
      WavFile cover;
      try {
        cover = await AudioInputLoader.loadPickedFile(
          fileName: fileName,
          bytes: bytes,
          path: path,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _processing = false;
          _statusMessage = audioLoadErrorMessage(s, e);
        });
        return;
      }

      if (!mounted) return;
      final preview = SpectrumAnalyzer.timelineFromWav(cover);
      setState(() {
        _eqBands = preview.isNotEmpty
            ? preview.first
            : List<double>.filled(kSpectrumBandCount, 0);
      });

      await _embedWithCover(cover, loadedName: fileName);
    } finally {
      _releaseEmbedInteractionLocks();
    }
  }

  Future<void> _embedWithCover(WavFile cover, {String? loadedName}) async {
    final s = AppStrings.of(context);
    final settings = ref.read(settingsProvider);
    final deploy = ref.read(appConfigProvider);
    final fixedBits = deploy.defaultFixedMessageBitLength;
    final useFixedLen = settings.defaultFixedMessageBitLimit;
    final available = cover.toMono().samples.length;

    late final int required;
    late final Uint8List? binaryMsg;
    if (_payloadKind == _EmbedPayloadKind.audio) {
      final payload = _payloadAudio;
      if (payload == null) {
        if (!mounted) return;
        _releaseEmbedInteractionLocks();
        await _showEmbedWarning(s.errorEmptyPayloadAudio);
        return;
      }
      try {
        binaryMsg = PayloadEnvelope.packAudioBits(
          payload,
          fixedBitLength: useFixedLen ? fixedBits : null,
        );
      } catch (_) {
        if (!mounted) return;
        _releaseEmbedInteractionLocks();
        await _showEmbedWarning(s.errorPayloadAudioBudget);
        return;
      }
      required = binaryMsg.length;
    } else if (_payloadKind == _EmbedPayloadKind.image) {
      final imageBytes = _payloadImageBytes;
      if (imageBytes == null) {
        if (!mounted) return;
        _releaseEmbedInteractionLocks();
        await _showEmbedWarning(s.errorEmptyPayloadImage);
        return;
      }
      try {
        binaryMsg = PayloadEnvelope.packImageBits(
          imageBytes,
          fixedBitLength: useFixedLen ? fixedBits : null,
        );
      } catch (_) {
        if (!mounted) return;
        _releaseEmbedInteractionLocks();
        await _showEmbedWarning(s.errorPayloadImageBudget);
        return;
      }
      required = binaryMsg.length;
    } else {
      binaryMsg = null;
      final text = _textCtrl.text.trim();
      if (text.isEmpty) {
        if (!mounted) return;
        _releaseEmbedInteractionLocks();
        await _showEmbedWarning(s.errorEmpty);
        return;
      }
      required = useFixedLen
          ? fixedBits
          : PayloadEnvelope.bitLengthForText(text);
      if (useFixedLen && PayloadEnvelope.bitLengthForText(text) > fixedBits) {
        if (!mounted) return;
        _releaseEmbedInteractionLocks();
        await _showEmbedWarning(s.errorTooLong);
        return;
      }
    }

    if (required > available) {
      if (!mounted) return;
      _releaseEmbedInteractionLocks();
      await _showEmbedWarning(s.errorTooLong);
      return;
    }

    EmbedRunResult? produced;
    String? error;
    try {
      if (_payloadKind == _EmbedPayloadKind.audio ||
          _payloadKind == _EmbedPayloadKind.image) {
        produced = await StegoRunner.embedBits(
          binaryMsg: binaryMsg!,
          cover: cover,
          r: settings.r,
          x0: settings.x0,
        );
      } else {
        produced = await StegoRunner.embed(
          text: _textCtrl.text.trim(),
          cover: cover,
          r: settings.r,
          x0: settings.x0,
          fixedMsgBitLength: useFixedLen ? fixedBits : null,
        );
      }
    } catch (e) {
      error = e.toString();
    }
    if (!mounted) return;
    final success = produced != null && error == null;
    setState(() {
      _processing = false;
      _cover = cover;
      _result = produced;
      _stego = produced?.stego;
      _embedInputHidden = success;
      if (error != null) {
        _statusMessage = _isEmbedCapacityError(error) ? null : error;
      } else if (loadedName != null) {
        _statusMessage = s.audioFileLoaded(loadedName);
      } else {
        _statusMessage = null;
      }
      _verifyStatus = null;
      _verifyOk = null;
    });
    if (error != null && _isEmbedCapacityError(error)) {
      await _showEmbedWarning(s.errorTooLong);
    } else if (error != null && _isEmbedIntegrityError(error)) {
      await _showEmbedWarning(s.errorEmbedIntegrity);
    }
    if (success) {
      setState(() {
        _verifyOk = true;
        _verifyStatus = s.verifyMatch;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _resultCardKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: 0.05,
          );
        }
      });
      final showRecovery =
          !useFixedLen && ref.read(appConfigProvider).showEmbedRecoveryDialog;
      await _showEmbedCompleteDialog(
        produced,
        showRecoveryReminder: showRecovery,
      );
    }
  }

  Future<void> _showEmbedCompleteDialog(
    EmbedRunResult result, {
    required bool showRecoveryReminder,
  }) async {
    if (!mounted) return;
    final s = AppStrings.of(context);
    final bits = result.msgBitLength;
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(s.embedCompleteTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!showRecoveryReminder)
                Text(
                  s.successSaved,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                )
              else ...[
                Text(
                  s.embedRecoveryMessage,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Material(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$bits',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: s.copy,
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: '$bits'),
                            );
                            if (!dialogCtx.mounted) return;
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              SnackBar(content: Text(s.embedRecoveryCopied)),
                            );
                          },
                          icon: const Icon(Icons.copy_outlined),
                        ),
                        const SizedBox(width: 4),
                        IconButton.filledTonal(
                          tooltip: s.shareStego,
                          onPressed: () async {
                            final outcome = await shareStegoWavBytes(
                              bytes: result.stego.encode(),
                              fileName: stegoWavFileName(result.msgBitLength),
                              subject: s.shareStego,
                            );
                            if (!dialogCtx.mounted) return;
                            final message = switch (outcome) {
                              StegoShareOutcome.fileDownloaded =>
                                s.shareFileDownloaded,
                              StegoShareOutcome.shared ||
                              StegoShareOutcome.textCopied => null,
                            };
                            if (message != null) {
                              ScaffoldMessenger.of(
                                dialogCtx,
                              ).showSnackBar(SnackBar(content: Text(message)));
                            }
                          },
                          icon: const Icon(Icons.share_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.embedRecoveryCapacityHint(result.capacityBits),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(s.embedRecoveryOk),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyRoundtrip() async {
    final stego = _stego;
    final result = _result;
    if (stego == null || result == null) return;
    final s = AppStrings.of(context);
    setState(() {
      _verifying = true;
      _verifyStatus = s.verifying;
      _verifyOk = null;
    });
    final settings = ref.read(settingsProvider);
    StegoPayloadResult? payload;
    try {
      payload = await StegoRunner.extractPayload(
        stego,
        msgBitLength: result.msgBitLength,
        r: settings.r,
        x0: settings.x0,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _verifyOk = false;
        _verifyStatus = e.toString();
      });
      return;
    }
    if (!mounted) return;
    final recoveredPayload = payload;
    if (recoveredPayload == null) {
      setState(() {
        _verifying = false;
        _verifyOk = false;
        _verifyStatus = s.verifyEmpty;
      });
      return;
    }
    final bool ok;
    if (_payloadKind == _EmbedPayloadKind.audio) {
      final original = _payloadAudio;
      final recovered = recoveredPayload.audio;
      if (original == null || recovered == null) {
        ok = false;
      } else {
        final expected = PayloadEnvelope.decodeAudioBody(
          PayloadEnvelope.encodeAudioBody(original),
        );
        ok = recovered.sampleRate == expected.sampleRate &&
            recovered.samples.length == expected.samples.length &&
            _int16ListsEqual(recovered.samples, expected.samples);
      }
    } else if (_payloadKind == _EmbedPayloadKind.image) {
      final original = _payloadImageBytes;
      final recovered = recoveredPayload.imageBytes;
      ok = original != null &&
          recovered != null &&
          _uint8ListsEqual(original, recovered);
    } else {
      final original = _textCtrl.text.trim();
      ok = recoveredPayload.text != null && recoveredPayload.text == original;
    }
    setState(() {
      _verifying = false;
      _verifyOk = ok;
      if (_payloadKind == _EmbedPayloadKind.audio) {
        _verifyStatus = ok
            ? s.verifyMatch
            : (recoveredPayload.audio == null
                ? s.verifyEmpty
                : s.verifyMismatch);
      } else if (_payloadKind == _EmbedPayloadKind.image) {
        _verifyStatus = ok
            ? s.verifyMatch
            : (recoveredPayload.imageBytes == null
                ? s.verifyEmpty
                : s.verifyMismatch);
      } else if (recoveredPayload.text == null ||
          recoveredPayload.text!.isEmpty) {
        _verifyStatus = s.verifyEmpty;
      } else {
        _verifyStatus = ok ? s.verifyMatch : s.verifyMismatch;
      }
    });
  }

  void _showStatus(String msg) {
    if (!mounted) return;
    setState(() => _statusMessage = msg);
  }

  Future<void> _showEmbedWarning(String message) async {
    if (!mounted) return;
    _releaseEmbedInteractionLocks();
    setState(() => _statusMessage = null);
    await showEmbedWarningDialog(context, message);
    _releaseEmbedInteractionLocks();
  }

  bool _isEmbedCapacityError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('too long') || lower.contains('message too long');
  }

  bool _isEmbedIntegrityError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('integrity') ||
        lower.contains('ber is') ||
        lower.contains('bit mismatch') ||
        lower.contains('wav round-trip') ||
        lower.contains('recovered');
  }

  bool _int16ListsEqual(Int16List a, Int16List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _uint8ListsEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool get _payloadReadyForCover => switch (_payloadKind) {
        _EmbedPayloadKind.text => _textCtrl.text.trim().isNotEmpty,
        _EmbedPayloadKind.audio => _payloadAudio != null,
        _EmbedPayloadKind.image => _payloadImageBytes != null,
      };

  Future<void> _pickPayloadImage() async {
    if (_busy || _processing || _recorder.isRecording) return;
    final s = AppStrings.of(context);
    FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
    } catch (e) {
      _showStatus(e.toString());
      return;
    }
    if (!mounted || picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    var bytes = file.bytes;
    if (bytes == null && file.path != null && !kIsWeb) {
      try {
        bytes = await nativeReadBytes(file.path!);
      } catch (e) {
        if (!mounted) return;
        _showStatus(e.toString());
        return;
      }
    }
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      await _showEmbedWarning(s.errorPayloadImageDecode);
      return;
    }

    final budget = _settingsBitBudget();
    late final Uint8List compressed;
    try {
      compressed = PayloadImageCodec.compressToFitBudget(
        bytes,
        bitBudget: budget,
      );
    } on FormatException {
      if (!mounted) return;
      await _showEmbedWarning(s.errorPayloadImageDecode);
      return;
    } catch (_) {
      if (!mounted) return;
      await _showEmbedWarning(s.errorPayloadImageBudget);
      return;
    }
    if (!mounted) return;
    setState(() {
      _payloadImageBytes = compressed;
      _payloadAudio = null;
      _statusMessage = s.payloadImageReady;
      _embedInputHidden = false;
    });
  }

  bool get _canStartNewEmbed =>
      _embedInputHidden ||
      _stego != null ||
      _cover != null ||
      _payloadAudio != null ||
      _payloadImageBytes != null ||
      _textCtrl.text.trim().isNotEmpty ||
      _recorder.isRecording ||
      _isPlaying ||
      _playbackLoaded ||
      _statusMessage != null ||
      _verifyStatus != null;

  bool get _newEmbedFabEnabled {
    if (_processing || _verifying) return false;
    if (_busy && !_recorder.isRecording) return false;
    return _embedInputHidden || _canStartNewEmbed;
  }

  Future<void> _startNewEmbed() async {
    if (_processing || _verifying) return;
    if (_busy && !_recorder.isRecording) return;
    _busy = true;
    try {
      if (_recorder.isRecording) {
        await _recorder.cancel();
      }
      await _cancelSpectrum();
      _clearRecordTimer();
      try {
        await _player.stop();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Embed new: stop playback: $e\n$st');
        }
      }
      if (!mounted) return;
      _textCtrl.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _processing = false;
        _verifying = false;
        _embedInputHidden = false;
        _payloadKind = _EmbedPayloadKind.text;
        _payloadAudio = null;
        _payloadImageBytes = null;
        _recordingPayload = false;
        _cover = null;
        _stego = null;
        _result = null;
        _statusMessage = null;
        _verifyStatus = null;
        _verifyOk = null;
        _eqBands = List<double>.filled(kSpectrumBandCount, 0);
        _isPlaying = false;
        _playbackLoaded = false;
      });
      SessionLog.write('Embed: new session');
      if (_scrollCtrl.hasClients) {
        unawaited(
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    } finally {
      if (mounted) {
        _busy = false;
      }
    }
  }

  Widget _buildNewEmbedFab(AppStrings s) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      shadowColor: scheme.shadow.withValues(alpha: 0.4),
      color: scheme.primaryContainer,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: s.embedNew,
        onPressed: _newEmbedFabEnabled ? _startNewEmbed : null,
        icon: Icon(Icons.note_add_outlined, color: scheme.onPrimaryContainer),
      ),
    );
  }

  Widget _buildHelpFab(AppStrings s) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      shadowColor: scheme.shadow.withValues(alpha: 0.4),
      color: scheme.secondaryContainer,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: s.helpTooltip,
        onPressed: () =>
            showHelpSheet(context, initialSection: HelpSection.embed),
        icon: Icon(
          Icons.help_outline_rounded,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Future<void> _saveStego() async {
    final stego = _stego;
    final result = _result;
    if (stego == null || result == null) return;
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final bytes = stego.encode();
    final defaultName = stegoWavFileName(result.msgBitLength);
    String? targetPath;
    try {
      targetPath = await FilePicker.saveFile(
        dialogTitle: s.saveStego,
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['wav'],
        bytes: bytes,
      );
    } on UnimplementedError {
      if (kIsWeb) rethrow;
      final dir = await getApplicationDocumentsDirectory();
      targetPath = p.join(dir.path, defaultName);
      await nativeWriteBytes(targetPath, bytes);
    }
    if (targetPath == null) {
      if (kIsWeb) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(s.successSaved)));
      }
      return;
    }
    if (!kIsWeb && !nativeFileExists(targetPath)) {
      await nativeWriteBytes(targetPath, bytes);
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          kIsWeb ? s.successSaved : '${s.successSaved}: $targetPath',
        ),
      ),
    );
  }

  Future<void> _shareStego() async {
    final stego = _stego;
    final result = _result;
    if (stego == null || result == null) return;
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final outcome = await shareStegoWavBytes(
        bytes: stego.encode(),
        fileName: stegoWavFileName(result.msgBitLength),
        subject: s.shareStego,
      );
      if (!mounted) return;
      final message = switch (outcome) {
        StegoShareOutcome.fileDownloaded => s.shareFileDownloaded,
        StegoShareOutcome.shared || StegoShareOutcome.textCopied => null,
      };
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _playStego() async {
    final stego = _stego;
    if (stego == null) return;
    try {
      _attachPlaybackSpectrum();
      if (_playbackLoaded && !_isPlaying && _player.hasSource) {
        await _player.resume();
      } else {
        await _player.playWav(stego);
      }
    } catch (e) {
      if (!mounted) return;
      _showStatus(e.toString());
    }
  }

  Future<void> _pauseStego() async {
    try {
      await _player.pause();
    } catch (e) {
      if (!mounted) return;
      _showStatus(e.toString());
    }
  }

  Future<void> _stopStego() async {
    try {
      await _player.stop();
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _playbackLoaded = false;
        _eqBands = List<double>.filled(kSpectrumBandCount, 0);
      });
    } catch (e) {
      if (!mounted) return;
      _showStatus(e.toString());
    }
  }

  String _messageBitCounterText(
    AppStrings s,
    bool useFixedLimit,
    int fixedBits,
  ) {
    final used = PayloadEnvelope.bitLengthForText(_textCtrl.text);
    if (useFixedLimit) {
      return s.messageBitsUsedAndRemaining(used, fixedBits - used);
    }
    return s.messageBitsUsed(used);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final settings = ref.watch(settingsProvider);
    final deploy = ref.watch(appConfigProvider);
    final useFixedLimit = settings.defaultFixedMessageBitLimit;
    final fixedBits = deploy.defaultFixedMessageBitLength;
    final appConfig = deploy;
    final isRecording = _recorder.isRecording;
    final eqActive = isRecording || _isPlaying || _playbackLoaded;
    final canPickFile = !isRecording && !_processing && !_busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNewEmbedFab(s),
                  const SizedBox(width: 8),
                  _buildHelpFab(s),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: TabScrollBody(
            scrollController: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (!_embedInputHidden) ...[
                SegmentedButton<_EmbedPayloadKind>(
                  segments: [
                    ButtonSegment(
                      value: _EmbedPayloadKind.text,
                      label: Text(s.embedPayloadTextTab),
                      icon: const Icon(Icons.message_outlined),
                    ),
                    ButtonSegment(
                      value: _EmbedPayloadKind.audio,
                      label: Text(s.embedPayloadAudioTab),
                      icon: const Icon(Icons.mic_none_outlined),
                    ),
                    ButtonSegment(
                      value: _EmbedPayloadKind.image,
                      label: Text(s.embedPayloadImageTab),
                      icon: const Icon(Icons.image_outlined),
                    ),
                  ],
                  selected: {_payloadKind},
                  onSelectionChanged: isRecording || _processing
                      ? null
                      : (next) {
                          final kind = next.first;
                          setState(() {
                            _payloadKind = kind;
                            if (kind == _EmbedPayloadKind.text) {
                              _payloadAudio = null;
                              _payloadImageBytes = null;
                              _recordingPayload = false;
                            } else if (kind == _EmbedPayloadKind.audio) {
                              _payloadImageBytes = null;
                            } else {
                              _payloadAudio = null;
                              _recordingPayload = false;
                            }
                            _statusMessage = null;
                          });
                        },
                ),
                const SizedBox(height: 12),
                if (_payloadKind == _EmbedPayloadKind.text)
                  DirectionalTextField(
                    controller: _textCtrl,
                    focusNode: _textFocus,
                    maxLines: 4,
                    minLines: 3,
                    scrollPhysics: const NeverScrollableScrollPhysics(),
                    enabled: !isRecording && !_processing,
                    inputFormatters: useFixedLimit
                        ? [MessageBitLengthFormatter(fixedBits)]
                        : const [],
                    decoration: InputDecoration(
                      labelText: s.textHint,
                      helperText: _messageBitCounterText(
                        s,
                        useFixedLimit,
                        fixedBits,
                      ),
                      helperMaxLines: 2,
                      prefixIcon: const Icon(Icons.message_outlined),
                    ),
                  )
                else if (_payloadKind == _EmbedPayloadKind.audio) ...[
                  Text(
                    s.embedPayloadAudioHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_payloadAudio != null) ...[
                    Text(
                      s.payloadAudioBudgetLabel(
                        PayloadEnvelope.bitLengthForAudio(_payloadAudio!),
                        fixedBits,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: isRecording || _processing
                            ? null
                            : () => setState(() {
                                  _payloadAudio = null;
                                  _statusMessage = null;
                                }),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(s.clearPayloadAudio),
                      ),
                    ),
                  ] else if (_recordingPayload && isRecording) ...[
                    Text(
                      s.payloadAudioBudgetLabel(
                        0,
                        fixedBits,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ] else ...[
                  Text(
                    s.embedPayloadImageHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_payloadImageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _payloadImageBytes!,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.payloadImageBudgetLabel(
                        PayloadEnvelope.bitLengthForImage(_payloadImageBytes!),
                        fixedBits,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: isRecording || _processing
                            ? null
                            : () => setState(() {
                                  _payloadImageBytes = null;
                                  _statusMessage = null;
                                }),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(s.clearPayloadImage),
                      ),
                    ),
                  ] else
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton.tonalIcon(
                        onPressed: isRecording || _processing
                            ? null
                            : _pickPayloadImage,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(s.pickPayloadImage),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                AudioFileDropSurface(
                  enabled: canPickFile && _payloadReadyForCover,
                  onFilePath: _embedFromDroppedPath,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      child: Column(
                      children: [
                        AudioEqualizerView(
                          bands: _eqBands,
                          active: eqActive,
                          recordingElapsed: isRecording
                              ? _recordingElapsed
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AudioSourceActionsPanel(
                          orLabel: s.audioSourceOr,
                          showLoadAction: appConfig.showEmbedLoadFileForUi &&
                              _payloadReadyForCover,
                          loadAction: CircleActionButton(
                            icon: Icons.upload_file_outlined,
                            label: s.loadAudioFile,
                            shape: ActionButtonShape.roundedSquare,
                            enabled: canPickFile && _payloadReadyForCover,
                            onPressed: _loadAndEmbed,
                            accent: CircleActionAccent.primary,
                          ),
                          recordAction: RecordButton(
                            isActive: isRecording,
                            enabled: isRecording || (!_processing && !_busy),
                            onPressed: _toggleRecord,
                            labelIdle: _payloadKind == _EmbedPayloadKind.audio &&
                                    _payloadAudio == null
                                ? s.recordPayloadAudio
                                : s.startRecording,
                            labelActive: _recordingPayload
                                ? s.stopPayloadAudio
                                : s.stopRecording,
                          ),
                        ),
                        if (_processing) ...[
                          const SizedBox(height: 12),
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ],
                        if (_statusMessage != null) ...[
                          const SizedBox(height: 12),
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
                const SizedBox(height: 16),
              ],
              if (_stego != null)
                KeyedSubtree(key: _resultCardKey, child: _buildResultCard(s)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(AppStrings s) {
    final theme = Theme.of(context);
    final stego = _stego!;
    final result = _result;
    final durationSec = stego.samples.length / stego.sampleRate;
    final scheme = theme.colorScheme;
    final onCard = scheme.onSurface;
    return Card(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  s.successSaved,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onCard,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildResultActions(s),
            if (_verifyStatus != null) ...[
              const SizedBox(height: 12),
              _buildVerifyBanner(theme),
            ],
            const SizedBox(height: 12),
            Material(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_cover != null) _buildCompareChart(s, theme),
                    if (result != null) ...[
                      if (_cover != null) const SizedBox(height: 12),
                      _buildMetricsBlock(s, theme, result, durationSec),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultActions(AppStrings s) {
    final scheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            foregroundColor: scheme.onPrimary,
            backgroundColor: scheme.primary,
          ),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Tooltip(
            message: s.play,
            child: IconButton.filled(
              onPressed: _verifying || _isPlaying ? null : _playStego,
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          ),
          Tooltip(
            message: s.pause,
            child: IconButton.filledTonal(
              onPressed: _verifying || !_isPlaying ? null : _pauseStego,
              icon: const Icon(Icons.pause_rounded),
            ),
          ),
          Tooltip(
            message: s.stopPlayback,
            child: IconButton.filledTonal(
              onPressed: _verifying || !_playbackLoaded ? null : _stopStego,
              icon: const Icon(Icons.stop_rounded),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: _verifying ? null : _saveStego,
            icon: const Icon(Icons.save_outlined),
            label: Text(s.saveStego),
          ),
          Tooltip(
            message: s.shareStego,
            child: IconButton.filledTonal(
              onPressed: _verifying ? null : _shareStego,
              icon: const Icon(Icons.share_outlined),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: _verifying ? null : _verifyRoundtrip,
            icon: _verifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_outlined),
            label: Text(s.verify),
          ),
          Builder(
            builder: (innerCtx) {
              return IconButton.filledTonal(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(innerCtx);
                  await Clipboard.setData(ClipboardData(text: _textCtrl.text));
                  messenger.showSnackBar(SnackBar(content: Text(s.copied)));
                },
                icon: const Icon(Icons.copy_outlined),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompareChart(AppStrings s, ThemeData theme) {
    final cover = _cover!;
    final stego = _stego!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.compareWaveformTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DualWaveformChart(
          coverEnvelope: waveformEnvelopeFromWav(cover),
          stegoEnvelope: waveformEnvelopeFromWav(stego),
          coverLabel: s.coverWaveLegend,
          stegoLabel: s.stegoWaveLegend,
        ),
      ],
    );
  }

  Widget _buildMetricsBlock(
    AppStrings s,
    ThemeData theme,
    EmbedRunResult result,
    double durationSec,
  ) {
    final chips = <Widget>[
      _metricChip(
        context,
        theme,
        EmbedMetricKind.duration,
        Icons.timer_outlined,
        s.duration,
        '${durationSec.toStringAsFixed(2)} s',
      ),
      _metricChip(
        context,
        theme,
        EmbedMetricKind.bitsEmbedded,
        Icons.token_outlined,
        s.bitsEmbedded,
        '${result.bitsEmbedded}',
      ),
      _metricChip(
        context,
        theme,
        EmbedMetricKind.capacity,
        Icons.storage_outlined,
        s.capacity,
        '${result.capacityBits}',
      ),
      _metricChip(
        context,
        theme,
        EmbedMetricKind.utilization,
        Icons.speed_outlined,
        s.utilization,
        '${(result.utilization * 100).toStringAsFixed(1)} %',
      ),
      if (!ref.watch(settingsProvider).defaultFixedMessageBitLimit)
        _metricChip(
          context,
          theme,
          EmbedMetricKind.msgBitLength,
          Icons.format_list_numbered,
          s.msgBitLength,
          '${result.msgBitLength}',
        ),
      if (result.snrDb != null && result.snrDb!.isFinite)
        _metricChip(
          context,
          theme,
          EmbedMetricKind.snr,
          Icons.graphic_eq,
          s.snrLabel,
          result.snrDb!.toStringAsFixed(2),
        ),
      if (result.psnrDb != null && result.psnrDb!.isFinite)
        _metricChip(
          context,
          theme,
          EmbedMetricKind.psnr,
          Icons.equalizer,
          s.psnrLabel,
          result.psnrDb!.toStringAsFixed(2),
        ),
      if (result.berPercent != null)
        _metricChip(
          context,
          theme,
          EmbedMetricKind.ber,
          Icons.percent,
          s.berLabel,
          result.berPercent!.toStringAsFixed(4),
        ),
      if (result.npcrPercent != null)
        _metricChip(
          context,
          theme,
          EmbedMetricKind.npcr,
          Icons.security,
          s.npcrLabel,
          result.npcrPercent!.toStringAsFixed(4),
        ),
      if (result.uaciPercent != null)
        _metricChip(
          context,
          theme,
          EmbedMetricKind.uaci,
          Icons.shield_outlined,
          s.uaciLabel,
          result.uaciPercent!.toStringAsFixed(4),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.qualityMetrics,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.metricHelpTapHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _metricChip(
    BuildContext context,
    ThemeData theme,
    EmbedMetricKind kind,
    IconData icon,
    String label,
    String value,
  ) {
    final scheme = theme.colorScheme;
    final strings = AppStrings.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showMetricHelpDialog(context, kind),
        borderRadius: BorderRadius.circular(20),
        child: Tooltip(
          message: strings.metricHelpTitle(kind),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  '$label: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyBanner(ThemeData theme) {
    final scheme = theme.colorScheme;
    final ok = _verifyOk;
    final color = ok == null
        ? scheme.surfaceContainerHighest
        : ok
        ? scheme.tertiaryContainer
        : scheme.errorContainer;
    final icon = ok == null
        ? Icons.hourglass_empty
        : ok
        ? Icons.check_circle
        : Icons.error_outline;
    final fg = ok == null
        ? scheme.onSurface
        : ok
        ? scheme.onTertiaryContainer
        : scheme.onErrorContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _verifyStatus ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
