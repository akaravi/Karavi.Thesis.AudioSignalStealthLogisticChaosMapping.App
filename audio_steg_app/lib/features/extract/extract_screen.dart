import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_strings.dart';
import '../../app/settings_controller.dart';
import '../../core/audio/audio_recorder.dart';
import '../../core/audio/wav_io.dart';
import '../../core/stego/stego.dart';
import '../shared/record_button.dart';
import '../shared/waveform_view.dart';

class ExtractScreen extends ConsumerStatefulWidget {
  const ExtractScreen({super.key});

  @override
  ConsumerState<ExtractScreen> createState() => _ExtractScreenState();
}

class _ExtractScreenState extends ConsumerState<ExtractScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final AudioRecorderService _recorder = AudioRecorderService();

  bool _busy = false;
  bool _processing = false;
  String? _result;
  String? _statusMessage;
  final List<double> _amps = [];
  StreamSubscription<double>? _ampSub;
  StreamSubscription<RecorderState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _recorder.stateStream.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _cancelAmp();
    unawaited(_recorder.dispose());
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _cancelAmp() async {
    final sub = _ampSub;
    _ampSub = null;
    if (sub != null) await sub.cancel();
  }

  Future<void> _pickAndExtract() async {
    if (_processing) return;
    final s = AppStrings.of(context);
    setState(() {
      _processing = true;
      _statusMessage = s.processing;
      _result = null;
    });

    FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wav'],
        withData: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _statusMessage = e.toString();
      });
      return;
    }

    if (!mounted) return;
    if (picked == null || picked.files.isEmpty) {
      setState(() {
        _processing = false;
        _statusMessage = null;
      });
      return;
    }

    final file = picked.files.first;
    Uint8List? bytes;
    try {
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else {
        throw StateError('No bytes/path available');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _statusMessage = e.toString();
      });
      return;
    }

    String? text;
    String? error;
    try {
      final wav = WavFile.decode(bytes);
      final settings = ref.read(settingsProvider);
      text = await StegoRunner.extract(wav, r: settings.r, x0: settings.x0);
    } catch (e) {
      error = e.toString();
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _result = text;
      _statusMessage = error ?? (text == null ? s.keyMismatch : null);
    });
  }

  Future<void> _toggleListen() async {
    if (_busy) return;
    _busy = true;
    try {
      if (_recorder.isRecording) {
        await _stopAndExtract();
      } else {
        await _startListening();
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _startListening() async {
    final s = AppStrings.of(context);
    try {
      await _recorder.start(sampleRate: 44100);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
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
      _result = null;
      _statusMessage = s.listening;
    });
  }

  Future<void> _stopAndExtract() async {
    final s = AppStrings.of(context);
    if (mounted) {
      setState(() {
        _processing = true;
        _statusMessage = s.processing;
      });
    }
    await _cancelAmp();

    WavFile? wav;
    try {
      wav = await _recorder.stopAndRead();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _statusMessage = e.toString();
      });
      return;
    }
    if (!mounted) return;
    if (wav == null) {
      setState(() {
        _processing = false;
        _statusMessage = 'No audio captured';
      });
      return;
    }

    final settings = ref.read(settingsProvider);
    String? text;
    String? error;
    try {
      text = await StegoRunner.extract(
        wav,
        mode: StegoMode.overTheAir,
        r: settings.r,
        x0: settings.x0,
      );
    } catch (e) {
      error = e.toString();
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _result = text;
      _statusMessage = error ?? (text == null ? s.keyMismatch : null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: s.fromFile, icon: const Icon(Icons.file_open_outlined)),
              Tab(text: s.fromMic, icon: const Icon(Icons.mic_none_outlined)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildFileTab(s),
              _buildMicTab(s),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileTab(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.audio_file_outlined,
                      size: 56, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(s.pickFile,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _processing ? null : _pickAndExtract,
                    icon: _processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_open),
                    label: Text(s.pickFile),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _resultCard(s),
        ],
      ),
    );
  }

  Widget _buildMicTab(AppStrings s) {
    final isListening = _recorder.isRecording;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                children: [
                  WaveformView(samples: _amps, active: isListening),
                  const SizedBox(height: 16),
                  RecordButton(
                    isActive: isListening,
                    onPressed: _processing ? () {} : _toggleListen,
                    iconIdle: Icons.hearing_outlined,
                    iconActive: Icons.stop_rounded,
                    labelIdle: s.listenLive,
                    labelActive: s.stopListening,
                  ),
                  if (_processing) ...[
                    const SizedBox(height: 12),
                    const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5)),
                  ],
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_statusMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _resultCard(s),
        ],
      ),
    );
  }

  Widget _resultCard(AppStrings s) {
    if (_result == null && _statusMessage == null) {
      return const SizedBox.shrink();
    }
    return Card(
      color: _result != null
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_result != null
                    ? Icons.check_circle_outline
                    : Icons.error_outline),
                const SizedBox(width: 8),
                Text(s.extractedText,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              _result ?? s.noText,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Builder(builder: (innerCtx) {
                  return TextButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(innerCtx);
                      await Clipboard.setData(ClipboardData(text: _result!));
                      messenger.showSnackBar(
                        SnackBar(content: Text(s.copied)),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(s.copy),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
