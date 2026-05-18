import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/app_strings.dart';
import '../../app/settings_controller.dart';
import '../../core/audio/audio_player.dart';
import '../../core/audio/audio_recorder.dart';
import '../../core/audio/wav_io.dart';
import '../../core/stego/stego.dart';
import '../shared/record_button.dart';
import '../shared/waveform_view.dart';

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
  WavFile? _stego;
  EmbedRunResult? _result;
  String? _statusMessage;
  String? _verifyStatus;
  bool? _verifyOk;
  final List<double> _amps = [];
  StreamSubscription<double>? _ampSub;
  StreamSubscription<RecorderState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _recorder.stateStream.listen((s) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _cancelAmp();
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelAmp() async {
    final sub = _ampSub;
    _ampSub = null;
    if (sub != null) await sub.cancel();
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
      await _recorder.start(sampleRate: 44100);
    } catch (e) {
      if (!mounted) return;
      _showStatus(e.toString());
      return;
    }
    if (!mounted) return;
    _amps.clear();
    final sub = _recorder.amplitudeStream().listen((db) {
      if (!mounted) return;
      setState(() {
        _amps.add(db);
        if (_amps.length > 200) _amps.removeAt(0);
      });
    });
    _ampSub = sub;
    setState(() {
      _stego = null;
      _result = null;
      _verifyStatus = null;
      _verifyOk = null;
      _statusMessage = s.recording;
    });
  }

  Future<void> _stopAndProcess() async {
    final s = AppStrings.of(context);
    if (mounted) {
      setState(() {
        _processing = true;
        _statusMessage = s.processing;
      });
    }
    await _cancelAmp();

    WavFile? cover;
    try {
      cover = await _recorder.stopAndRead();
    } catch (e) {
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

    final settings = ref.read(settingsProvider);
    final text = _textCtrl.text.trim();

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
      _result = produced;
      _stego = produced?.stego;
      _statusMessage = error;
      _verifyStatus = null;
      _verifyOk = null;
    });
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

  Future<void> _saveStego() async {
    final stego = _stego;
    if (stego == null) return;
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final bytes = stego.encode();
    String? targetPath;
    try {
      targetPath = await FilePicker.saveFile(
        dialogTitle: s.saveStego,
        fileName: 'stego_${DateTime.now().millisecondsSinceEpoch}.wav',
        type: FileType.custom,
        allowedExtensions: ['wav'],
        bytes: bytes,
      );
    } on UnimplementedError {
      final dir = await getApplicationDocumentsDirectory();
      targetPath =
          '${dir.path}${Platform.pathSeparator}'
          'stego_${DateTime.now().millisecondsSinceEpoch}.wav';
      await File(targetPath).writeAsBytes(bytes);
    }
    if (targetPath == null) return;
    if (!File(targetPath).existsSync()) {
      await File(targetPath).writeAsBytes(bytes);
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('${s.successSaved}: $targetPath')),
    );
  }

  Future<void> _playStego() async {
    final stego = _stego;
    if (stego == null) return;
    try {
      await _player.playWav(stego);
    } catch (e) {
      if (!mounted) return;
      _showStatus(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isRecording = _recorder.isRecording;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textCtrl,
              maxLines: 4,
              minLines: 3,
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
                    WaveformView(samples: _amps, active: isRecording),
                    const SizedBox(height: 16),
                    RecordButton(
                      isActive: isRecording,
                      onPressed: _processing ? () {} : _toggleRecord,
                      labelIdle: s.startRecording,
                      labelActive: s.stopRecording,
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
      ),
    );
  }

  Widget _buildResultCard(AppStrings s) {
    final theme = Theme.of(context);
    final stego = _stego!;
    final result = _result;
    final durationSec = stego.samples.length / stego.sampleRate;
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline),
                const SizedBox(width: 8),
                Text(s.successSaved, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (result != null)
              _buildMetricsBlock(s, theme, result, durationSec),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _verifying ? null : _playStego,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(s.play),
                ),
                FilledButton.tonalIcon(
                  onPressed: _verifying ? null : _saveStego,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(s.saveStego),
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
                        await Clipboard.setData(
                          ClipboardData(text: _textCtrl.text),
                        );
                        messenger.showSnackBar(
                          SnackBar(content: Text(s.copied)),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined),
                    );
                  },
                ),
              ],
            ),
            if (_verifyStatus != null) ...[
              const SizedBox(height: 12),
              _buildVerifyBanner(theme),
            ],
          ],
        ),
      ),
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
    final ok = _verifyOk;
    final color = ok == null
        ? theme.colorScheme.surface
        : ok
        ? Colors.green.withValues(alpha: 0.15)
        : Colors.red.withValues(alpha: 0.15);
    final icon = ok == null
        ? Icons.hourglass_empty
        : ok
        ? Icons.check_circle
        : Icons.error_outline;
    final fg = ok == null
        ? theme.colorScheme.onSurface
        : ok
        ? Colors.green.shade700
        : Colors.red.shade700;
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
