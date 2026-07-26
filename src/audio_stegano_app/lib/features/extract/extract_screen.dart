import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;

import '../../app/app_strings.dart';
import '../../app/app_config_provider.dart';
import '../../app/opened_audio_file.dart';
import '../../app/pending_open_audio_provider.dart';
import '../../app/settings_controller.dart';
import '../../core/audio/audio_input_loader.dart';
import '../../core/audio/audio_load_errors.dart';
import '../../core/audio/audio_player.dart';
import '../../core/audio/wav_io.dart';
import '../../core/stego/stego.dart';
import '../shared/audio_file_drop_surface.dart';
import '../shared/directional_selectable_text.dart';
import '../shared/directional_text_field.dart';
import '../shared/help_sheet.dart';
import '../shared/tab_scroll_body.dart';

class ExtractScreen extends ConsumerStatefulWidget {
  const ExtractScreen({super.key});

  @override
  ConsumerState<ExtractScreen> createState() => _ExtractScreenState();
}

class _ExtractScreenState extends ConsumerState<ExtractScreen> {
  final _bitLenCtrl = TextEditingController();
  /// Cover (stego file) and recovered payload must never share one player —
  /// otherwise pause/stop/play on one stream replaces or freezes the other.
  final AudioPlayerService _coverPlayer = AudioPlayerService();
  final AudioPlayerService _extractedPlayer = AudioPlayerService();

  bool _processing = false;
  bool _loadingFile = false;
  bool _extractionAttempted = false;
  String? _result;
  WavFile? _extractedAudio;
  String? _statusMessage;
  String? _bitLengthError;
  WavFile? _loadedWav;
  bool _coverPlaying = false;
  bool _coverLoaded = false;
  bool _extractedPlaying = false;
  StreamSubscription<PlayerState>? _coverStateSub;
  StreamSubscription<PlayerState>? _extractedStateSub;

  @override
  void dispose() {
    _coverStateSub?.cancel();
    _extractedStateSub?.cancel();
    unawaited(_coverPlayer.dispose());
    unawaited(_extractedPlayer.dispose());
    _bitLenCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAudioFile({
    required String fileName,
    Uint8List? bytes,
    String? path,
  }) async {
    if (_processing) return;
    final s = AppStrings.of(context);

    setState(() {
      _loadingFile = true;
      _statusMessage = s.processing;
      _extractionAttempted = false;
      _result = null;
      _extractedAudio = null;
    });

    WavFile? wav;
    String? error;
    try {
      wav = await AudioInputLoader.loadPickedFile(
        fileName: fileName,
        bytes: bytes,
        path: kIsWeb ? null : path,
      );
    } catch (e) {
      error = audioLoadErrorMessage(s, e);
    }

    await _coverPlayer.stop();
    await _extractedPlayer.stop();
    if (!mounted) return;
    setState(() {
      _loadingFile = false;
      _loadedWav = wav;
      _coverPlaying = false;
      _coverLoaded = false;
      _extractedPlaying = false;
      if (error != null) {
        _statusMessage = error;
      } else if (wav != null) {
        _statusMessage = s.audioFileLoaded(fileName);
      }
    });
  }

  void _attachCoverListeners() {
    _coverStateSub ??= _coverPlayer.stateStream.listen((st) {
      if (!mounted) return;
      final completed = st.processingState == ProcessingState.completed;
      setState(() {
        _coverPlaying = completed ? false : st.playing;
        _coverLoaded =
            _loadedWav != null && (_coverPlayer.hasSource || completed);
      });
    });
  }

  void _attachExtractedListeners() {
    _extractedStateSub ??= _extractedPlayer.stateStream.listen((st) {
      if (!mounted) return;
      final completed = st.processingState == ProcessingState.completed;
      setState(() {
        _extractedPlaying = completed ? false : st.playing;
      });
    });
  }

  int? _parseBitLength(AppStrings s) {
    final raw = _bitLenCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _bitLengthError = s.errorBitLengthEmpty);
      return null;
    }
    final n = int.tryParse(raw);
    if (n == null || n <= 0) {
      setState(() => _bitLengthError = s.errorBitLengthInvalid);
      return null;
    }
    setState(() => _bitLengthError = null);
    return n;
  }

  Future<void> _pickAudio() async {
    if (_processing) return;

    FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: AudioInputLoader.audioPickerExtensions,
        withData: kIsWeb,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
      return;
    }

    if (!mounted) return;
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final fileName = file.name;
    if (fileName.isEmpty) {
      if (!mounted) return;
      setState(() => _statusMessage = AppStrings.of(context).keyMismatch);
      return;
    }

    await _loadAudioFile(
      fileName: fileName,
      bytes: file.bytes,
      path: file.path,
    );
  }

  Future<void> _extract() async {
    if (_processing) return;
    final s = AppStrings.of(context);
    final wav = _loadedWav;
    if (wav == null) {
      setState(() => _statusMessage = s.errorNoAudioLoaded);
      return;
    }

    final settings = ref.read(settingsProvider);
    final deploy = ref.read(appConfigProvider);
    final useFixedLen = settings.defaultFixedMessageBitLimit;
    final msgBitLength = useFixedLen
        ? deploy.defaultFixedMessageBitLength
        : _parseBitLength(s);
    if (msgBitLength == null) return;

    setState(() {
      _processing = true;
      _result = null;
      _extractedAudio = null;
      _statusMessage = s.processing;
      _extractionAttempted = false;
      _extractedPlaying = false;
    });
    unawaited(_extractedPlayer.stop());

    StegoPayloadResult? payload;
    String? error;
    try {
      payload = await StegoRunner.extractPayload(
        wav,
        msgBitLength: msgBitLength,
        r: settings.r,
        x0: settings.x0,
      );
    } catch (e) {
      error = e.toString();
    }
    if (!mounted) return;

    String? text;
    WavFile? audio;
    String? status;
    if (error != null) {
      status = error;
    } else if (payload == null) {
      status = s.keyMismatch;
    } else if (payload.audio != null) {
      audio = payload.audio;
      status = null;
    } else if (payload.rawBody != null && payload.text == null) {
      status = s.extractUnsupportedType;
    } else if (payload.text == null) {
      status = s.keyMismatch;
    } else if (payload.text!.isEmpty) {
      text = '';
      status = s.noText;
    } else {
      text = payload.text;
      status = null;
    }

    setState(() {
      _processing = false;
      _extractionAttempted = true;
      _result = text;
      _extractedAudio = audio;
      _statusMessage = status;
    });
  }

  Future<void> _playLoaded() async {
    final wav = _loadedWav;
    if (wav == null) return;
    try {
      // Pause payload player so streams stay independent (no shared source).
      if (_extractedPlaying) {
        await _extractedPlayer.pause();
      }
      _attachCoverListeners();
      if (_coverLoaded && !_coverPlaying && _coverPlayer.hasSource) {
        await _coverPlayer.resume();
      } else {
        await _coverPlayer.playWav(wav);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
    }
  }

  Future<void> _pauseLoaded() async {
    try {
      await _coverPlayer.pause();
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
    }
  }

  Future<void> _stopLoaded() async {
    try {
      await _coverPlayer.stop();
      if (!mounted) return;
      setState(() {
        _coverPlaying = false;
        _coverLoaded = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
    }
  }

  String _resultBody(AppStrings s) {
    if (_extractedAudio != null) return s.extractedAudio;
    if (_result != null && _result!.isNotEmpty) return _result!;
    if (_result != null && _result!.isEmpty) return s.noText;
    return _statusMessage ?? s.noText;
  }

  bool get _extractSucceeded =>
      (_result != null && _result!.isNotEmpty) || _extractedAudio != null;

  bool get _hasLoadedAudio => _loadedWav != null;

  bool get _canStartNewExtract =>
      _loadedWav != null ||
      _bitLenCtrl.text.trim().isNotEmpty ||
      _extractionAttempted ||
      _result != null ||
      _extractedAudio != null ||
      _statusMessage != null ||
      _coverPlaying ||
      _coverLoaded ||
      _extractedPlaying;

  bool get _newExtractFabEnabled {
    if (_processing || _loadingFile) return false;
    return _canStartNewExtract;
  }

  Future<void> _startNewExtract() async {
    if (!_newExtractFabEnabled) return;
    try {
      await _coverPlayer.stop();
      await _extractedPlayer.stop();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Extract new: stop playback: $e');
      }
    }
    if (!mounted) return;
    _bitLenCtrl.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _processing = false;
      _loadingFile = false;
      _extractionAttempted = false;
      _loadedWav = null;
      _result = null;
      _extractedAudio = null;
      _statusMessage = null;
      _bitLengthError = null;
      _coverPlaying = false;
      _coverLoaded = false;
      _extractedPlaying = false;
    });
  }

  Future<void> _playExtractedAudio() async {
    final wav = _extractedAudio;
    if (wav == null) return;
    try {
      if (_coverPlaying) {
        await _coverPlayer.pause();
      }
      _attachExtractedListeners();
      if (_extractedPlaying && _extractedPlayer.hasSource) {
        await _extractedPlayer.pause();
        return;
      }
      if (_extractedPlayer.hasSource && !_extractedPlaying) {
        await _extractedPlayer.resume();
        return;
      }
      await _extractedPlayer.playWav(
        PayloadEnvelope.prepareAudioForExport(wav),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
    }
  }

  Future<void> _saveExtractedAudio() async {
    final wav = _extractedAudio;
    if (wav == null) return;
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final bytes = PayloadEnvelope.prepareAudioForExport(wav).encode();
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: s.saveExtractedAudio,
        fileName: 'extracted_payload.wav',
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

  Widget _buildNewExtractFab(AppStrings s) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      shadowColor: scheme.shadow.withValues(alpha: 0.4),
      color: scheme.primaryContainer,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: s.extractNew,
        onPressed: _newExtractFabEnabled ? _startNewExtract : null,
        icon: Icon(Icons.note_add_outlined, color: scheme.onPrimaryContainer),
      ),
    );
  }

  Widget _buildPlaybackControls(AppStrings s) {
    if (!_hasLoadedAudio) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            foregroundColor: scheme.onPrimary,
            backgroundColor: scheme.primary,
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: s.play,
            child: IconButton.filled(
              onPressed: _processing || _coverPlaying ? null : _playLoaded,
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: s.pause,
            child: IconButton.filledTonal(
              onPressed: _processing || !_coverPlaying ? null : _pauseLoaded,
              icon: const Icon(Icons.pause_rounded),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: s.stopPlayback,
            child: IconButton.filledTonal(
              onPressed: _processing || !_coverLoaded ? null : _stopLoaded,
              icon: const Icon(Icons.stop_rounded),
            ),
          ),
        ],
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
            showHelpSheet(context, initialSection: HelpSection.extract),
        icon: Icon(
          Icons.help_outline_rounded,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OpenedAudioFile?>(pendingOpenAudioFileProvider, (prev, next) {
      if (next == null) return;
      ref.read(pendingOpenAudioFileProvider.notifier).clear();
      unawaited(_loadAudioFile(fileName: next.displayName, path: next.path));
    });

    final s = AppStrings.of(context);
    final useFixedLen = ref.watch(settingsProvider).defaultFixedMessageBitLimit;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TabScrollBody(
          padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
          children: [
            AudioFileDropSurface(
              enabled: !_processing && !_loadingFile,
              onFilePath: (path) =>
                  unawaited(_loadAudioFile(fileName: p.basename(path), path: path)),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.audio_file_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.pickFile,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (!useFixedLen) ...[
                      const SizedBox(height: 16),
                      DirectionalTextField(
                        forceLatinLtr: true,
                        controller: _bitLenCtrl,
                        keyboardType: TextInputType.number,
                        scrollPhysics: const NeverScrollableScrollPhysics(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        enabled: !_processing,
                        onChanged: (_) {
                          if (_bitLengthError != null) {
                            setState(() => _bitLengthError = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: s.msgBitLengthHint,
                          helperText: s.msgBitLengthHelper,
                          errorText: _bitLengthError,
                          prefixIcon: const Icon(Icons.format_list_numbered),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _processing || _loadingFile
                              ? null
                              : _pickAudio,
                          icon: _loadingFile
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.folder_open),
                          label: Text(s.pickFile),
                        ),
                        _buildPlaybackControls(s),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _processing || !_hasLoadedAudio
                          ? null
                          : _extract,
                      icon: const Icon(Icons.lock_open_outlined),
                      label: Text(s.extractTab),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: 16),
            _resultCard(s),
          ],
        ),
        PositionedDirectional(
          top: 8,
          end: 8,
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNewExtractFab(s),
                const SizedBox(width: 8),
                _buildHelpFab(s),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultCard(AppStrings s) {
    if (!_extractionAttempted) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final isAudio = _extractedAudio != null;
    return Card(
      color: _extractSucceeded
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  _extractSucceeded
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                ),
                const SizedBox(width: 8),
                Text(
                  isAudio ? s.extractedAudio : s.extractedText,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isAudio)
              DirectionalSelectableText(
                _resultBody(s),
                style: theme.textTheme.bodyLarge,
              )
            else
              Text(_resultBody(s), style: theme.textTheme.bodyLarge),
            if (_extractSucceeded) ...[
              const SizedBox(height: 12),
              if (isAudio)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _playExtractedAudio,
                      icon: Icon(
                        _extractedPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        _extractedPlaying ? s.pause : s.playExtractedAudio,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _saveExtractedAudio,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(s.saveExtractedAudio),
                    ),
                  ],
                )
              else
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Builder(
                    builder: (innerCtx) {
                      return TextButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(innerCtx);
                          await Clipboard.setData(
                            ClipboardData(text: _result!),
                          );
                          messenger.showSnackBar(
                            SnackBar(content: Text(s.copied)),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: Text(s.copy),
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
