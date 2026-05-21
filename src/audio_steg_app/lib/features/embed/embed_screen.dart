import 'dart:async';

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
import '../../core/io/native_file.dart';
import '../../app/session_log.dart';
import '../../app/settings_controller.dart';
import '../../core/audio/audio_input_loader.dart';
import '../../core/audio/audio_player.dart';
import '../../core/audio/audio_recorder.dart';
import '../../core/audio/stego_file_naming.dart';
import '../../core/audio/wav_io.dart';
import '../../core/audio/spectrum_analyzer.dart';
import '../../core/audio/waveform_display.dart';
import '../../core/stego/stego.dart';
import '../shared/audio_equalizer_view.dart';
import '../shared/dual_waveform_chart.dart';
import '../shared/circle_action_button.dart';
import '../shared/record_button.dart';
import '../shared/stego_share.dart';
import '../shared/tab_scroll_body.dart';

class EmbedScreen extends ConsumerStatefulWidget {
  const EmbedScreen({super.key});

  @override
  ConsumerState<EmbedScreen> createState() => _EmbedScreenState();
}

class _EmbedScreenState extends ConsumerState<EmbedScreen> {
  final _textCtrl = TextEditingController();
  final AudioRecorderService _recorder = AudioRecorderService();
  final AudioPlayerService _player = AudioPlayerService();

  bool _busy = false;
  bool _processing = false;
  bool _verifying = false;
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
    _busy = true;
    try {
      if (_recorder.isRecording) {
        await _stopAndProcess();
      } else {
        await _startRecording();
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _startRecording() async {
    final s = AppStrings.of(context);
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      _showStatus(s.errorEmpty);
      return;
    }
    try {
      SessionLog.write('Embed: record start');
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
  }

  Future<void> _loadAndEmbed() async {
    if (_busy || _processing || _recorder.isRecording) return;
    final s = AppStrings.of(context);
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      _showStatus(s.errorEmpty);
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

    _busy = true;
    setState(() {
      _processing = true;
      _statusMessage = s.processing;
    });

    WavFile cover;
    try {
      cover = await AudioInputLoader.loadPickedFile(
        fileName: name,
        bytes: file.bytes,
        path: kIsWeb ? null : file.path,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _processing = false;
        _statusMessage = e.toString().contains('MP3 decode failed')
            ? s.errorMp3Decode
            : e.toString();
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

    await _embedWithCover(cover, loadedName: name);
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<void> _embedWithCover(WavFile cover, {String? loadedName}) async {
    final s = AppStrings.of(context);
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _statusMessage = s.errorEmpty;
      });
      return;
    }

    final required = MessageBits.bitLengthForText(text);
    final available = cover.toMono().samples.length;
    if (required > available) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _statusMessage =
            '${s.errorTooLong} ($required bits > $available samples)';
      });
      return;
    }

    final settings = ref.read(settingsProvider);
    EmbedRunResult? produced;
    String? error;
    try {
      produced = await StegoRunner.embed(
        text: text,
        cover: cover,
        r: settings.r,
        x0: settings.x0,
      );
    } catch (e) {
      error = e.toString();
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _cover = cover;
      _result = produced;
      _stego = produced?.stego;
      if (error != null) {
        _statusMessage = error;
      } else if (loadedName != null) {
        _statusMessage = s.audioFileLoaded(loadedName);
      } else {
        _statusMessage = null;
      }
      _verifyStatus = null;
      _verifyOk = null;
    });
    if (produced != null &&
        error == null &&
        ref.read(appConfigProvider).showEmbedRecoveryDialog) {
      await _showRecoveryBitsDialog(produced);
    }
  }

  Future<void> _showRecoveryBitsDialog(EmbedRunResult result) async {
    if (!mounted) return;
    final s = AppStrings.of(context);
    final bits = result.msgBitLength;
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(s.embedCompleteTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                          await Clipboard.setData(ClipboardData(text: '$bits'));
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
    String? extracted;
    try {
      extracted = await StegoRunner.extract(
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
    final original = _textCtrl.text.trim();
    final ok = extracted != null && extracted == original;
    setState(() {
      _verifying = false;
      _verifyOk = ok;
      if (extracted == null || extracted.isEmpty) {
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

  bool get _canStartNewEmbed =>
      _stego != null ||
      _cover != null ||
      _textCtrl.text.trim().isNotEmpty ||
      _recorder.isRecording ||
      _isPlaying ||
      _playbackLoaded ||
      _statusMessage != null ||
      _verifyStatus != null;

  bool get _newEmbedFabEnabled {
    if (_processing || _verifying) return _recorder.isRecording;
    if (_busy && !_recorder.isRecording) return false;
    return _canStartNewEmbed;
  }

  Future<void> _startNewEmbed() async {
    if (!_newEmbedFabEnabled) return;
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

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final appConfig = ref.watch(appConfigProvider);
    final isRecording = _recorder.isRecording;
    final eqActive = isRecording || _isPlaying || _playbackLoaded;
    final canPickFile = !isRecording && !_processing && !_busy;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TabScrollBody(
          padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
          children: [
            TextField(
              controller: _textCtrl,
              maxLines: 4,
              minLines: 3,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              enabled: !isRecording && !_processing,
              decoration: InputDecoration(
                labelText: s.textHint,
                prefixIcon: const Icon(Icons.message_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Card(
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
                      recordingElapsed: isRecording ? _recordingElapsed : null,
                    ),
                    const SizedBox(height: 16),
                    AudioSourceActionsPanel(
                      orLabel: s.audioSourceOr,
                      showLoadAction: appConfig.showEmbedLoadFileButton,
                      loadAction: CircleActionButton(
                        icon: Icons.upload_file_outlined,
                        label: s.loadAudioFile,
                        shape: ActionButtonShape.roundedSquare,
                        enabled: canPickFile,
                        onPressed: _loadAndEmbed,
                        accent: CircleActionAccent.primary,
                      ),
                      recordAction: RecordButton(
                        isActive: isRecording,
                        enabled: !_processing && (isRecording || !_busy),
                        onPressed: _toggleRecord,
                        labelIdle: s.startRecording,
                        labelActive: s.stopRecording,
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
            const SizedBox(height: 16),
            if (_stego != null) _buildResultCard(s),
          ],
        ),
        PositionedDirectional(
          top: 8,
          end: 8,
          child: SafeArea(bottom: false, child: _buildNewEmbedFab(s)),
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
        theme,
        Icons.timer_outlined,
        s.duration,
        '${durationSec.toStringAsFixed(2)} s',
      ),
      _metricChip(
        theme,
        Icons.token_outlined,
        s.bitsEmbedded,
        '${result.bitsEmbedded}',
      ),
      _metricChip(
        theme,
        Icons.storage_outlined,
        s.capacity,
        '${result.capacityBits}',
      ),
      _metricChip(
        theme,
        Icons.speed_outlined,
        s.utilization,
        '${(result.utilization * 100).toStringAsFixed(1)} %',
      ),
      _metricChip(
        theme,
        Icons.format_list_numbered,
        s.msgBitLength,
        '${result.msgBitLength}',
      ),
      if (result.snrDb != null && result.snrDb!.isFinite)
        _metricChip(
          theme,
          Icons.graphic_eq,
          s.snrLabel,
          result.snrDb!.toStringAsFixed(2),
        ),
      if (result.psnrDb != null && result.psnrDb!.isFinite)
        _metricChip(
          theme,
          Icons.equalizer,
          s.psnrLabel,
          result.psnrDb!.toStringAsFixed(2),
        ),
      if (result.berPercent != null)
        _metricChip(
          theme,
          Icons.percent,
          s.berLabel,
          result.berPercent!.toStringAsFixed(4),
        ),
      if (result.npcrPercent != null)
        _metricChip(
          theme,
          Icons.security,
          s.npcrLabel,
          result.npcrPercent!.toStringAsFixed(4),
        ),
      if (result.uaciPercent != null)
        _metricChip(
          theme,
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
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _metricChip(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
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
        ],
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
