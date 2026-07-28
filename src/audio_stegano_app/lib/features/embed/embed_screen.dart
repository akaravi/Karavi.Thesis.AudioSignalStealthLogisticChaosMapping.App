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
import '../../app/app_icon_accents.dart';
import '../../app/app_strings.dart';
import '../../app/busy_overlay_provider.dart';
import '../../app/metric_help_strings.dart';
import '../../core/io/native_file.dart';
import '../../app/session_log.dart';
import '../../app/settings_controller.dart';
import '../../core/audio/audio_input_loader.dart';
import '../../core/audio/audio_load_errors.dart';
import '../../core/audio/audio_recorder.dart';
import '../../core/audio/playback_hub.dart';
import '../../core/audio/sample_rate_reconcile.dart';
import '../../core/audio/stego_file_naming.dart';
import '../../core/audio/wav_io.dart';
import '../../core/audio/spectrum_analyzer.dart';
import '../../core/audio/waveform_display.dart';
import '../../core/stego/cover_record_budget.dart';
import '../../core/stego/stego.dart';
import '../shared/accent_icon.dart';
import '../shared/audio_file_drop_surface.dart';
import '../shared/audio_equalizer_view.dart';
import '../shared/app_section_card.dart';
import '../shared/dual_waveform_chart.dart';
import '../shared/circle_action_button.dart';
import '../shared/directional_selectable_text.dart';
import '../shared/directional_text_field.dart';
import '../shared/embed_metric_kind.dart';
import '../shared/help_sheet.dart';
import '../shared/embed_warning_dialog.dart';
import '../shared/metric_help_dialog.dart';
import '../shared/message_bit_length_formatter.dart';
import '../shared/page_app_bar.dart';
import '../shared/page_toolbar_fab.dart';
import '../shared/record_button.dart';
import '../shared/stego_share.dart';
import '../shared/tab_scroll_body.dart';
import '../../app/app_ui_tokens.dart';

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
  final _hub = PlaybackHub.instance;

  bool _busy = false;
  bool _processing = false;
  bool _verifying = false;

  /// After a successful embed, payload tabs + record/load stay hidden until New.
  /// Derived from `_stego` so UI cannot desync (input visible while result card shows).
  bool get _embedInputHidden => _stego != null;
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
  StegoPayloadResult? _recoveredPayload;
  bool _coverPlaying = false;
  bool _stegoPlaying = false;
  bool _payloadOriginalPlaying = false;
  bool _payloadRecoveredPlaying = false;
  bool _coverLoaded = false;
  bool _stegoLoaded = false;
  List<double> _eqBands = List<double>.filled(kSpectrumBandCount, 0);
  final List<StreamSubscription<PlayerState>> _playStateSubs = [];
  final List<StreamSubscription<List<double>>> _spectrumSubs = [];
  StreamSubscription<RecorderState>? _stateSub;
  StreamSubscription<List<double>>? _recordSpectrumSub;
  DateTime? _recordStartedAt;
  Timer? _recordTickTimer;

  bool get _abPlaying => _coverPlaying || _stegoPlaying;
  bool get _abLoaded => _coverLoaded || _stegoLoaded;

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
    _bindPlaybackHub();
  }

  void _bindPlaybackHub() {
    void syncFlags() {
      if (!mounted) return;
      setState(() {
        _coverPlaying = _hub.isPlaying(PlaybackSessionId.embedCover);
        _stegoPlaying = _hub.isPlaying(PlaybackSessionId.embedStego);
        _payloadOriginalPlaying =
            _hub.isPlaying(PlaybackSessionId.embedPayloadOriginal);
        _payloadRecoveredPlaying =
            _hub.isPlaying(PlaybackSessionId.embedPayloadRecovered);
        _coverLoaded = _hub.hasSource(PlaybackSessionId.embedCover);
        _stegoLoaded = _hub.hasSource(PlaybackSessionId.embedStego);
        if (!_abPlaying) {
          _eqBands = List<double>.filled(kSpectrumBandCount, 0);
        }
      });
    }

    for (final id in PlaybackHub.embedSessions) {
      _playStateSubs.add(_hub.listenState(id, (_) => syncFlags()));
    }
    for (final id in PlaybackHub.abSessions) {
      _spectrumSubs.add(_hub.listenSpectrum(id, (bands) {
        if (!mounted) return;
        if (!_hub.isPlaying(id)) return;
        setState(() => _eqBands = List<double>.from(bands));
      }));
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _publishAppBusyOverlay();
  }

  void _publishAppBusyOverlay() {
    if (!mounted) return;
    final s = AppStrings.of(context);
    final String? message;
    if (_verifying) {
      message = s.verifying;
    } else if (_processing) {
      message = s.processing;
    } else {
      message = null;
    }
    final controller = ref.read(appBusyMessageProvider.notifier);
    if (ref.read(appBusyMessageProvider) != message) {
      if (message == null) {
        controller.clear();
      } else {
        controller.show(message);
      }
    }
  }

  @override
  void dispose() {
    ref.read(appBusyMessageProvider.notifier).clear();
    _recordTickTimer?.cancel();
    _stateSub?.cancel();
    _recordSpectrumSub?.cancel();
    for (final s in _playStateSubs) {
      unawaited(s.cancel());
    }
    for (final s in _spectrumSubs) {
      unawaited(s.cancel());
    }
    unawaited(_recorder.dispose());
    unawaited(_hub.stopSessions(PlaybackHub.embedSessions));
    _textCtrl.dispose();
    _textFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelRecordSpectrum() async {
    final sub = _recordSpectrumSub;
    _recordSpectrumSub = null;
    if (sub != null) await sub.cancel();
  }

  Future<void> _toggleRecord() async {
    if (_busy) return;
    if (_recorder.isRecording) {
      if (_recordingPayload) {
        await _stopPayloadRecording();
      } else if (!_coverRecordMinSatisfied) {
        final s = AppStrings.of(context);
        final remain = _coverRecordRemainingSeconds;
        _showStatus(s.recordingTooShort(remain));
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
    _recordSpectrumSub = sub;
    _recordStartedAt = DateTime.now();
    _recordTickTimer?.cancel();
    _recordTickTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || !_recorder.isRecording) return;
      final settings = ref.read(settingsProvider);
      if (settings.defaultFixedMessageBitLimit) {
        final budget = _settingsBitBudget();
        final maxSamples =
            PayloadAudioDefaults.maxPcmSamplesForBitBudget(budget);
        if (maxSamples > 0 &&
            _recorder.bufferedMonoSampleCount >= maxSamples) {
          unawaited(_stopPayloadRecording());
          return;
        }
      }
      setState(() {
        if (_payloadCapacityBudgetBits != null) {
          final s = AppStrings.of(context);
          if (_payloadRecordCapacitySatisfied) {
            _statusMessage = s.payloadRecordCapacityFull;
          } else {
            final remain = _payloadRecordCapacityRemainingSeconds;
            _statusMessage =
                '${s.payloadRecordCapacityProgress} ${s.payloadRecordCapacityRemaining(remain)}';
          }
        }
      });
    });
    setState(() {
      _recordingPayload = true;
      _cover = null;
      _stego = null;
      _result = null;
      _verifyStatus = null;
      _verifyOk = null;
      final budgetBits = _payloadCapacityBudgetBits;
      if (budgetBits != null) {
        final remain = _payloadNeedSecondsForBudget(budgetBits);
        _statusMessage =
            '${s.payloadRecordCapacityProgress} ${s.payloadRecordCapacityRemaining(remain)}';
      } else {
        _statusMessage = s.recording;
      }
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
      await _cancelRecordSpectrum();
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
      if (settings.defaultFixedMessageBitLimit && bitsNeeded > budget) {
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
    _recordSpectrumSub = sub;
    _recordStartedAt = DateTime.now();
    _recordTickTimer?.cancel();
    _recordTickTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || !_recorder.isRecording) return;
      setState(() {
        if (!_recordingPayload && _coverRequiredBits != null) {
          final s = AppStrings.of(context);
          if (_coverRecordMinSatisfied) {
            _statusMessage = s.recordingMinReached;
          } else {
            final remain = _coverRecordRemainingSeconds;
            _statusMessage =
                '${s.recordingMinProgress} ${s.recordingMinRemaining(remain)}';
          }
        }
      });
    });
    setState(() {
      _recordingPayload = false;
      _cover = null;
      _stego = null;
      _result = null;
      _verifyStatus = null;
      _verifyOk = null;
      final bits = _coverRequiredBits;
      if (bits != null) {
        final remain = CoverRecordBudget.remainingFromSamples(
          bufferedSamples: 0,
          requiredBits: bits,
        ).inSeconds.clamp(1, 3600);
        _statusMessage =
            '${s.recordingMinProgress} ${s.recordingMinRemaining(remain)}';
      } else {
        _statusMessage = s.recording;
      }
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

  /// Bits the cover must hold: fixed settings budget, or live payload size.
  int? get _coverRequiredBits {
    if (_recordingPayload) return null;
    final settings = ref.read(settingsProvider);
    if (settings.defaultFixedMessageBitLimit) {
      final bits = ref.read(appConfigProvider).defaultFixedMessageBitLength;
      return bits > 0 ? bits : null;
    }
    switch (_payloadKind) {
      case _EmbedPayloadKind.audio:
        final a = _payloadAudio;
        if (a == null) return null;
        final n = PayloadEnvelope.bitLengthForAudio(a);
        return n > 0 ? n : null;
      case _EmbedPayloadKind.image:
        final img = _payloadImageBytes;
        if (img == null) return null;
        final n = PayloadEnvelope.bitLengthForImage(img);
        return n > 0 ? n : null;
      case _EmbedPayloadKind.text:
        final text = _textCtrl.text.trim();
        if (text.isEmpty) return null;
        final n = PayloadEnvelope.bitLengthForText(text);
        return n > 0 ? n : null;
    }
  }

  int _coverNeedSecondsForBits(int bits) {
    return CoverRecordBudget.remainingFromSamples(
      bufferedSamples: 0,
      requiredBits: bits,
      sampleRate: CoverRecordBudget.coverSampleRate,
    ).inSeconds.clamp(1, 3600);
  }

  bool get _coverRecordMinSatisfied {
    final bits = _coverRequiredBits;
    if (bits == null) return true;
    return CoverRecordBudget.samplesSatisfied(
      _recorder.bufferedMonoSampleCount,
      bits,
    );
  }

  double get _coverRecordProgress {
    final bits = _coverRequiredBits;
    if (bits == null) return 1;
    return CoverRecordBudget.progressFromSamples(
      _recorder.bufferedMonoSampleCount,
      bits,
    );
  }

  int get _coverRecordRemainingSeconds {
    final bits = _coverRequiredBits;
    if (bits == null) return 0;
    return CoverRecordBudget.remainingFromSamples(
      bufferedSamples: _recorder.bufferedMonoSampleCount,
      requiredBits: bits,
      sampleRate: _recorder.currentSampleRate > 0
          ? _recorder.currentSampleRate
          : CoverRecordBudget.coverSampleRate,
    ).inSeconds.clamp(1, 3600);
  }

  /// Fixed bit budget while recording secret payload voice (settings checkbox on).
  int? get _payloadCapacityBudgetBits {
    if (!_recordingPayload) return null;
    final settings = ref.read(settingsProvider);
    if (!settings.defaultFixedMessageBitLimit) return null;
    final bits = _settingsBitBudget();
    return bits > 0 ? bits : null;
  }

  int _payloadNeedSecondsForBudget(int bitBudget) {
    final maxSamples =
        PayloadAudioDefaults.maxPcmSamplesForBitBudget(bitBudget);
    if (maxSamples <= 0) return 1;
    final rate = _recorder.currentSampleRate > 0
        ? _recorder.currentSampleRate
        : PayloadAudioDefaults.sampleRate;
    return (maxSamples / rate).ceil().clamp(1, 3600);
  }

  bool get _payloadRecordCapacitySatisfied {
    final budget = _payloadCapacityBudgetBits;
    if (budget == null) return false;
    final maxSamples =
        PayloadAudioDefaults.maxPcmSamplesForBitBudget(budget);
    return maxSamples > 0 &&
        _recorder.bufferedMonoSampleCount >= maxSamples;
  }

  double get _payloadRecordCapacityProgress {
    final budget = _payloadCapacityBudgetBits;
    if (budget == null) return 0;
    final maxSamples =
        PayloadAudioDefaults.maxPcmSamplesForBitBudget(budget);
    if (maxSamples <= 0) return 1;
    final p = _recorder.bufferedMonoSampleCount / maxSamples;
    if (p.isNaN || p.isInfinite) return 0;
    return p.clamp(0.0, 1.0);
  }

  int get _payloadRecordCapacityRemainingSeconds {
    final budget = _payloadCapacityBudgetBits;
    if (budget == null) return 0;
    final maxSamples =
        PayloadAudioDefaults.maxPcmSamplesForBitBudget(budget);
    final need = maxSamples - _recorder.bufferedMonoSampleCount;
    if (need <= 0) return 0;
    final rate = _recorder.currentSampleRate > 0
        ? _recorder.currentSampleRate
        : PayloadAudioDefaults.sampleRate;
    return (need / rate).ceil().clamp(1, 3600);
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
      await _cancelRecordSpectrum();
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
      await _showEmbedWarning(
        s.errorCapacityExceeded(required, available),
      );
      return;
    }

    EmbedRunResult? produced;
    String? error;
    CapacityExceededException? capacityError;
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
      capacityError = CapacityExceededException.tryParse(e);
      if (capacityError == null) {
        error = e.toString();
      }
    }
    if (!mounted) return;
    final success = produced != null && error == null && capacityError == null;
    try {
      await _hub.stopSessions(PlaybackHub.embedSessions);
    } catch (_) {}
    setState(() {
      _processing = false;
      _cover = cover;
      _result = produced;
      // Null on failure → input stays/resumes; non-null → input hidden via getter.
      _stego = produced?.stego;
      if (capacityError != null) {
        _statusMessage = null;
      } else if (error != null) {
        _statusMessage = _isEmbedCapacityError(error) ? null : error;
      } else if (loadedName != null) {
        _statusMessage = s.audioFileLoaded(loadedName);
      } else {
        _statusMessage = null;
      }
      _verifyStatus = null;
      _verifyOk = null;
      _recoveredPayload = null;
      _coverPlaying = false;
      _stegoPlaying = false;
      _payloadOriginalPlaying = false;
      _payloadRecoveredPlaying = false;
      _coverLoaded = false;
      _stegoLoaded = false;
    });
    if (capacityError != null) {
      await _showEmbedWarning(
        s.errorCapacityExceeded(
          capacityError.neededBits,
          capacityError.availableBits,
        ),
      );
    } else if (error != null && _isEmbedCapacityError(error)) {
      final parsed = CapacityExceededException.tryParse(error);
      if (parsed != null) {
        await _showEmbedWarning(
          s.errorCapacityExceeded(parsed.neededBits, parsed.availableBits),
        );
      } else {
        await _showEmbedWarning(
          s.errorCapacityExceeded(required, available),
        );
      }
    } else if (error != null && _isEmbedIntegrityError(error)) {
      await _showEmbedWarning(s.errorEmbedIntegrity);
    }
    if (success) {
      // Immediate verify: extract from stego now so the user can test recovered content.
      await _verifyRoundtrip();
      final showRecovery =
          !useFixedLen && ref.read(appConfigProvider).showEmbedRecoveryDialog;
      await _showEmbedCompleteDialog(
        produced,
        showRecoveryReminder: showRecovery,
      );
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _resultCardKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            alignment: 0.05,
          );
        }
      });
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
                  s.operationSuccess,
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
    try {
      await _hub.stopSessions([
      PlaybackSessionId.embedPayloadOriginal,
      PlaybackSessionId.embedPayloadRecovered,
    ]);
    } catch (_) {}
    setState(() {
      _verifying = true;
      _verifyStatus = s.verifying;
      _verifyOk = null;
      _recoveredPayload = null;
      _payloadOriginalPlaying = false;
      _payloadRecoveredPlaying = false;
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
        _recoveredPayload = null;
        _payloadOriginalPlaying = false;
        _payloadRecoveredPlaying = false;
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
        _recoveredPayload = null;
        _payloadOriginalPlaying = false;
        _payloadRecoveredPlaying = false;
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
      _recoveredPayload = recoveredPayload;
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

  Future<void> _playOriginalPayloadAudio() async {
    final wav = _payloadAudio;
    if (wav == null) return;
    try {
      await _hub.playOrToggle(
        PlaybackSessionId.embedPayloadOriginal,
        PayloadEnvelope.prepareAudioForExport(wav),
      );
    } catch (e) {
      if (!mounted) return;
      _showStatus(e.toString());
    }
  }

  Future<void> _playRecoveredAudio() async {
    final wav = _recoveredPayload?.audio;
    if (wav == null) return;
    try {
      await _hub.playOrToggle(
        PlaybackSessionId.embedPayloadRecovered,
        PayloadEnvelope.prepareAudioForExport(wav),
      );
    } catch (e) {
      if (!mounted) return;
      _showStatus(e.toString());
    }
  }

  Future<void> _saveRecoveredAudio() async {
    final wav = _recoveredPayload?.audio;
    if (wav == null) return;
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final bytes = PayloadEnvelope.prepareAudioForExport(wav).encode();
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: s.saveExtractedAudio,
        fileName: 'verified_payload.wav',
        type: FileType.custom,
        allowedExtensions: ['wav'],
        bytes: bytes,
      );
      if (path == null) {
        if (kIsWeb && mounted) {
          messenger.showSnackBar(SnackBar(content: Text(s.successSaved)));
        }
        return;
      }
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.successSaved)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _saveRecoveredImage() async {
    final imageBytes = _recoveredPayload?.imageBytes;
    if (imageBytes == null) return;
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isPng = imageBytes.length >= 4 &&
        imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50;
    final ext = isPng ? 'png' : 'jpg';
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: s.saveExtractedImage,
        fileName: 'verified_payload.$ext',
        type: FileType.custom,
        allowedExtensions: [ext],
        bytes: imageBytes,
      );
      if (path == null) {
        if (kIsWeb && mounted) {
          messenger.showSnackBar(SnackBar(content: Text(s.successSaved)));
        }
        return;
      }
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.successSaved)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
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
    if (CapacityExceededException.tryParse(message) != null) return true;
    final lower = message.toLowerCase();
    return lower.contains('too long') ||
        lower.contains('message too long') ||
        lower.contains('capacity exceeded');
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

    final budget = ref.read(settingsProvider).defaultFixedMessageBitLimit
        ? _settingsBitBudget()
        : null;
    late final Uint8List compressed;
    try {
      compressed = PayloadImageCodec.compressForEmbed(
        bytes,
        bitBudget: budget,
      );
    } on FormatException {
      if (!mounted) return;
      await _showEmbedWarning(s.errorPayloadImageDecode);
      return;
    } catch (_) {
      if (!mounted) return;
      await _showEmbedWarning(
        budget != null ? s.errorPayloadImageBudget : s.errorPayloadImageDecode,
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _payloadImageBytes = compressed;
      _payloadAudio = null;
      _statusMessage = s.payloadImageReady;
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
      _abPlaying ||
      _abLoaded ||
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
      await _cancelRecordSpectrum();
      _clearRecordTimer();
      try {
        await _hub.stopSessions(PlaybackHub.embedSessions);
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
        _recoveredPayload = null;
        _coverPlaying = false;
        _stegoPlaying = false;
        _payloadOriginalPlaying = false;
        _payloadRecoveredPlaying = false;
        _coverLoaded = false;
        _stegoLoaded = false;
        _eqBands = List<double>.filled(kSpectrumBandCount, 0);
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
    return PageToolbarFab(
      tooltip: s.embedNew,
      icon: Icons.note_add_outlined,
      onPressed: _newEmbedFabEnabled ? _startNewEmbed : null,
      primary: true,
    );
  }

  Widget _buildHelpFab(AppStrings s) {
    return PageToolbarFab(
      tooltip: s.helpTooltip,
      icon: Icons.help_outline_rounded,
      onPressed: () =>
          showHelpSheet(context, initialSection: HelpSection.embed),
      primary: false,
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

  Future<void> _playCover() async {
    final wav = _cover;
    if (wav == null) return;
    try {
      await _hub.playIfNotPlaying(PlaybackSessionId.embedCover, wav);
    } catch (e) {
      if (!mounted) return;
      _showStatus(e.toString());
    }
  }

  Future<void> _playStego() async {
    final wav = _stego;
    if (wav == null) return;
    try {
      await _hub.playIfNotPlaying(PlaybackSessionId.embedStego, wav);
    } catch (e) {
      if (!mounted) return;
      _showStatus(e.toString());
    }
  }

  Future<void> _pauseCover() async {
    try {
      await _hub.pause(PlaybackSessionId.embedCover);
    } catch (e) {
      if (!mounted) return;
      _showStatus(e.toString());
    }
  }

  Future<void> _pauseStegoSide() async {
    try {
      await _hub.pause(PlaybackSessionId.embedStego);
    } catch (e) {
      if (!mounted) return;
      _showStatus(e.toString());
    }
  }

  Future<void> _stopCover() async {
    try {
      await _hub.stop(PlaybackSessionId.embedCover);
      if (!mounted) return;
      setState(() {
        if (!_abPlaying) {
          _eqBands = List<double>.filled(kSpectrumBandCount, 0);
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showStatus(e.toString());
    }
  }

  Future<void> _stopStegoSide() async {
    try {
      await _hub.stop(PlaybackSessionId.embedStego);
      if (!mounted) return;
      setState(() {
        if (!_abPlaying) {
          _eqBands = List<double>.filled(kSpectrumBandCount, 0);
        }
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
    if (used <= 0) return s.messageBitsUsed(used);
    final needSec = _coverNeedSecondsForBits(used);
    return '${s.messageBitsUsed(used)}\n${s.coverRecordNeedHint(used, needSec)}';
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
    final eqActive = isRecording || _abPlaying || _abLoaded;
    final canPickFile = !isRecording && !_processing && !_busy;
    return Scaffold(
      appBar: PageAppBar(
        title: s.embedTab,
        actions: [
          _buildNewEmbedFab(s),
          _buildHelpFab(s),
        ],
      ),
      body: TabScrollBody(
            scrollController: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              // Input only while no stego result; New FAB clears `_stego`.
              if (_stego == null) ...[
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
                    useFixedLimit
                        ? s.embedPayloadAudioHint
                        : s.embedPayloadAudioHintDynamic,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_payloadAudio != null) ...[
                    Text(
                      useFixedLimit
                          ? s.payloadAudioBudgetLabel(
                              PayloadEnvelope.bitLengthForAudio(_payloadAudio!),
                              fixedBits,
                            )
                          : s.payloadAudioBitsRequired(
                              PayloadEnvelope.bitLengthForAudio(_payloadAudio!),
                            ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (!useFixedLimit) ...[
                      const SizedBox(height: 4),
                      Text(
                        s.coverRecordNeedHint(
                          PayloadEnvelope.bitLengthForAudio(_payloadAudio!),
                          _coverNeedSecondsForBits(
                            PayloadEnvelope.bitLengthForAudio(_payloadAudio!),
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
                  ] else if (_recordingPayload && isRecording && useFixedLimit) ...[
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
                    useFixedLimit
                        ? s.embedPayloadImageHint
                        : s.embedPayloadImageHintDynamic,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_payloadImageBytes != null) ...[
                    ClipRRect(
                      borderRadius: AppUiTokens.imageBorderRadius,
                      child: Image.memory(
                        _payloadImageBytes!,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      useFixedLimit
                          ? s.payloadImageBudgetLabel(
                              PayloadEnvelope.bitLengthForImage(
                                _payloadImageBytes!,
                              ),
                              fixedBits,
                            )
                          : s.payloadImageBitsRequired(
                              PayloadEnvelope.bitLengthForImage(
                                _payloadImageBytes!,
                              ),
                            ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (!useFixedLimit) ...[
                      const SizedBox(height: 4),
                      Text(
                        s.coverRecordNeedHint(
                          PayloadEnvelope.bitLengthForImage(
                            _payloadImageBytes!,
                          ),
                          _coverNeedSecondsForBits(
                            PayloadEnvelope.bitLengthForImage(
                              _payloadImageBytes!,
                            ),
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
                  child: AppSectionCard(
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
                        if (isRecording &&
                            _recordingPayload &&
                            _payloadCapacityBudgetBits != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _payloadRecordCapacityProgress,
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _payloadRecordCapacitySatisfied
                                ? s.payloadRecordCapacityFull
                                : s.payloadRecordCapacityProgress,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (isRecording &&
                            !_recordingPayload &&
                            _coverRequiredBits != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _coverRecordProgress,
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _coverRecordMinSatisfied
                                ? s.recordingMinReached
                                : s.recordingMinProgress,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
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
                        if (_statusMessage != null && !_processing) ...[
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
                const SizedBox(height: AppUiTokens.sectionGap),
              ],
              if (_stego != null)
                KeyedSubtree(key: _resultCardKey, child: _buildResultCard(s)),
            ],
          ),
    );
  }

  Widget _buildResultCard(AppStrings s) {
    final theme = Theme.of(context);
    final stego = _stego!;
    final result = _result;
    final durationSec = stego.samples.length / stego.sampleRate;
    final scheme = theme.colorScheme;
    final gap = AppUiTokens.sectionGapResult;

    return AppSectionCard(
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildResultHero(s, theme, scheme),
          SizedBox(height: gap),
          _buildResultActions(s),
          if (_verifyStatus != null) ...[
            SizedBox(height: gap),
            _buildVerifyBanner(theme),
          ],
          if (_cover != null && _stego != null) ...[
            SizedBox(height: gap),
            _buildAbListenPanel(s, theme),
          ],
          if (_recoveredPayload != null) ...[
            SizedBox(height: gap),
            _buildRecoveredPayloadPanel(s, theme),
          ],
          SizedBox(height: gap),
          _buildAnalysisPanel(s, theme, result, durationSec),
        ],
      ),
    );
  }

  Widget _resultBlock({required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(AppUiTokens.resultBlockRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppUiTokens.resultBlockPadding),
        child: child,
      ),
    );
  }

  Widget _buildResultHero(AppStrings s, ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccentGlowIcon(
          Icons.check_circle_rounded,
          accent: AppIconAccent.verify,
          size: 30,
          tileSize: AppUiTokens.resultHeroIconSize + 24,
        ),
        const SizedBox(height: 8),
        Text(
          s.operationSuccess,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.operationSuccessSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildResultActions(AppStrings s) {
    final showCopy = _payloadKind == _EmbedPayloadKind.text &&
        _textCtrl.text.trim().isNotEmpty;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AccentActionIconButton(
          tooltip: s.saveStego,
          icon: Icons.save_outlined,
          accent: AppIconAccent.save,
          filled: true,
          onPressed: _verifying ? null : _saveStego,
        ),
        AccentActionIconButton(
          tooltip: s.shareStego,
          icon: Icons.share_outlined,
          accent: AppIconAccent.share,
          onPressed: _verifying ? null : _shareStego,
        ),
        AccentActionIconButton(
          tooltip: s.verify,
          icon: Icons.verified_outlined,
          accent: AppIconAccent.verify,
          onPressed: _verifying ? null : _verifyRoundtrip,
          busyChild: _verifying
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppIconAccents.foreground(
                      AppIconAccent.verify,
                      Theme.of(context).brightness,
                    ),
                  ),
                )
              : null,
        ),
        if (showCopy)
          Builder(
            builder: (innerCtx) {
              return AccentActionIconButton(
                tooltip: s.copy,
                icon: Icons.copy_outlined,
                accent: AppIconAccent.copy,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(innerCtx);
                  await Clipboard.setData(
                    ClipboardData(text: _textCtrl.text),
                  );
                  messenger.showSnackBar(
                    SnackBar(content: Text(s.copied)),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildAbListenPanel(AppStrings s, ThemeData theme) {
    final scheme = theme.colorScheme;
    final coverPlaying = _coverPlaying;
    final stegoPlaying = _stegoPlaying;
    final coverTransport =
        coverPlaying || _hub.isPaused(PlaybackSessionId.embedCover);
    final stegoTransport =
        stegoPlaying || _hub.isPaused(PlaybackSessionId.embedStego);
    return _resultBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.verifyAbListenTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= AppUiTokens.resultContentBreakpoint;
              final originalCard = _buildAbListenSideCard(
                theme: theme,
                scheme: scheme,
                s: s,
                badge: 'A',
                title: s.abListenOriginalShort,
                playLabel: s.playOriginalCover,
                playing: coverPlaying,
                showTransport: coverTransport && !_verifying,
                emphasized: false,
                onPlay: _verifying || _cover == null ? null : _playCover,
                onPause: coverTransport && !_verifying ? _pauseCover : null,
                onStop: coverTransport && !_verifying ? _stopCover : null,
              );
              final stegoCard = _buildAbListenSideCard(
                theme: theme,
                scheme: scheme,
                s: s,
                badge: 'B',
                title: s.abListenStegoShort,
                playLabel: s.playStegoAudio,
                playing: stegoPlaying,
                showTransport: stegoTransport && !_verifying,
                emphasized: true,
                onPlay: _verifying || _stego == null ? null : _playStego,
                onPause: stegoTransport && !_verifying ? _pauseStegoSide : null,
                onStop: stegoTransport && !_verifying ? _stopStegoSide : null,
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: originalCard),
                    const SizedBox(width: 8),
                    Expanded(child: stegoCard),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  originalCard,
                  const SizedBox(height: 8),
                  stegoCard,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAbListenSideCard({
    required ThemeData theme,
    required ColorScheme scheme,
    required AppStrings s,
    required String badge,
    required String title,
    required String playLabel,
    required bool playing,
    required bool showTransport,
    required bool emphasized,
    required VoidCallback? onPlay,
    required VoidCallback? onPause,
    required VoidCallback? onStop,
  }) {
    final borderColor = playing
        ? scheme.primary
        : scheme.outlineVariant.withValues(alpha: emphasized ? 0.55 : 0.4);
    final fill = emphasized
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.06),
            scheme.surface,
          )
        : scheme.surface.withValues(alpha: 0.88);
    final badgeBg = emphasized
        ? scheme.primary.withValues(alpha: 0.9)
        : scheme.secondaryContainer.withValues(alpha: 0.85);
    final badgeFg =
        emphasized ? scheme.onPrimary : scheme.onSecondaryContainer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: playing ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    badge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (showTransport) ...[
                Tooltip(
                  message: s.pause,
                  child: IconButton.filledTonal(
                    onPressed: onPause,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.pause_rounded),
                  ),
                ),
                Tooltip(
                  message: s.stopPlayback,
                  child: IconButton.filledTonal(
                    onPressed: onStop,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.stop_rounded),
                  ),
                ),
              ],
              Tooltip(
                message: playLabel,
                child: emphasized
                    ? IconButton.filled(
                        onPressed: onPlay,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          playing
                              ? Icons.graphic_eq_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      )
                    : IconButton.filledTonal(
                        onPressed: onPlay,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          playing
                              ? Icons.graphic_eq_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisPanel(
    AppStrings s,
    ThemeData theme,
    EmbedRunResult? result,
    double durationSec,
  ) {
    return _resultBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.analysisSectionTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          if (_cover != null) _buildCompareChart(s, theme),
          if (result != null) ...[
            if (_cover != null) const SizedBox(height: 14),
            _buildMetricsBlock(s, theme, result, durationSec),
          ],
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
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.85)
        : ok
        ? scheme.tertiaryContainer.withValues(alpha: 0.82)
        : scheme.errorContainer.withValues(alpha: 0.88);
    final icon = ok == null
        ? Icons.hourglass_empty
        : ok
        ? Icons.check_circle_outline_rounded
        : Icons.error_outline;
    final fg = ok == null
        ? scheme.onSurfaceVariant
        : ok
        ? scheme.onTertiaryContainer
        : scheme.onErrorContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (ok == true
                  ? scheme.tertiary
                  : ok == false
                  ? scheme.error
                  : scheme.outlineVariant)
              .withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _verifyStatus ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: fg,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveredPayloadPanel(AppStrings s, ThemeData theme) {
    final payload = _recoveredPayload;
    if (payload == null) return const SizedBox.shrink();
    final scheme = theme.colorScheme;
    final isAudio = payload.audio != null;
    final isImage = payload.imageBytes != null;
    final originalPlaying = _payloadOriginalPlaying;
    final recoveredPlaying = _payloadRecoveredPlaying;

    Widget originalColumn() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.originalHiddenPayload,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (isImage) ...[
            if (_payloadImageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _payloadImageBytes!,
                  height: 140,
                  fit: BoxFit.contain,
                ),
              )
            else
              Text('—', style: theme.textTheme.bodyMedium),
          ] else if (isAudio) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Tooltip(
                message: originalPlaying
                    ? s.pause
                    : s.playOriginalPayloadAudio,
                child: IconButton.filledTonal(
                  onPressed: _verifying || _payloadAudio == null
                      ? null
                      : _playOriginalPayloadAudio,
                  icon: Icon(
                    originalPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ),
            ),
          ] else ...[
            DirectionalSelectableText(
              _textCtrl.text.trim(),
              style: theme.textTheme.bodyMedium,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Tooltip(
                message: s.copy,
                child: IconButton.filledTonal(
                  onPressed: () async {
                    final text = _textCtrl.text.trim();
                    if (text.isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(ClipboardData(text: text));
                    messenger.showSnackBar(
                      SnackBar(content: Text(s.copied)),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                ),
              ),
            ),
          ],
        ],
      );
    }

    Widget recoveredColumn() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.recoveredPayloadLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (isImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                payload.imageBytes!,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Tooltip(
                message: s.saveExtractedImage,
                child: IconButton.filledTonal(
                  onPressed: _verifying ? null : _saveRecoveredImage,
                  icon: const Icon(Icons.save_outlined),
                ),
              ),
            ),
          ] else if (isAudio)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                Tooltip(
                  message: recoveredPlaying ? s.pause : s.playExtractedAudio,
                  child: IconButton.filledTonal(
                    onPressed: _verifying ? null : _playRecoveredAudio,
                    icon: Icon(
                      recoveredPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                ),
                Tooltip(
                  message: s.saveExtractedAudio,
                  child: IconButton.filledTonal(
                    onPressed: _verifying ? null : _saveRecoveredAudio,
                    icon: const Icon(Icons.save_outlined),
                  ),
                ),
              ],
            )
          else ...[
            DirectionalSelectableText(
              payload.text ?? '',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Tooltip(
                message: s.copy,
                child: IconButton.filledTonal(
                  onPressed: () async {
                    final text = payload.text;
                    if (text == null || text.isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(ClipboardData(text: text));
                    messenger.showSnackBar(
                      SnackBar(content: Text(s.copied)),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return _resultBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.verifyRecoveredTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= AppUiTokens.resultContentBreakpoint;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: originalColumn()),
                    const SizedBox(width: 16),
                    Expanded(child: recoveredColumn()),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  originalColumn(),
                  const SizedBox(height: 16),
                  Divider(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  recoveredColumn(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
