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
import '../../app/busy_overlay_provider.dart';
import '../../app/opened_audio_file.dart';
import '../../app/pending_open_audio_provider.dart';
import '../../app/settings_controller.dart';
import '../../core/audio/audio_input_loader.dart';
import '../../core/audio/audio_load_errors.dart';
import '../../core/audio/playback_hub.dart';
import '../../core/audio/wav_io.dart';
import '../../core/stego/stego.dart';
import '../shared/audio_file_drop_surface.dart';
import '../shared/app_section_card.dart';
import '../shared/directional_selectable_text.dart';
import '../shared/directional_text_field.dart';
import '../shared/help_sheet.dart';
import '../shared/page_toolbar_fab.dart';
import '../shared/tab_scroll_body.dart';
import '../../app/app_ui_tokens.dart';

class ExtractScreen extends ConsumerStatefulWidget {
  const ExtractScreen({super.key});

  @override
  ConsumerState<ExtractScreen> createState() => _ExtractScreenState();
}

class _ExtractScreenState extends ConsumerState<ExtractScreen> {
  final _bitLenCtrl = TextEditingController();
  final _hub = PlaybackHub.instance;
  final GlobalKey _resultCardKey = GlobalKey();
  final ScrollController _scrollCtrl = ScrollController();

  bool _processing = false;
  bool _loadingFile = false;
  bool _extractionAttempted = false;

  /// After a successful extract, pick/load card stays hidden until new extract.
  bool _extractInputHidden = false;
  String? _result;
  WavFile? _extractedAudio;
  Uint8List? _extractedImageBytes;
  String? _statusMessage;
  String? _bitLengthError;
  WavFile? _loadedWav;
  bool _coverPlaying = false;
  bool _coverLoaded = false;
  bool _extractedPlaying = false;
  final List<StreamSubscription<PlayerState>> _playSubs = [];

  @override
  void initState() {
    super.initState();
    for (final id in PlaybackHub.extractSessions) {
      _playSubs.add(_hub.listenState(id, (_) {
        if (!mounted) return;
        setState(() {
          _coverPlaying = _hub.isPlaying(PlaybackSessionId.extractCover);
          _coverLoaded = _hub.hasSource(PlaybackSessionId.extractCover);
          _extractedPlaying = _hub.isPlaying(PlaybackSessionId.extractPayload);
        });
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
    if (_processing || _loadingFile) {
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
    for (final s in _playSubs) {
      unawaited(s.cancel());
    }
    unawaited(_hub.stopSessions(PlaybackHub.extractSessions));
    _bitLenCtrl.dispose();
    _scrollCtrl.dispose();
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
      _extractInputHidden = false;
      _result = null;
      _extractedAudio = null;
      _extractedImageBytes = null;
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

    await _hub.stopSessions(PlaybackHub.extractSessions);
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
      _extractedImageBytes = null;
      _statusMessage = s.processing;
      _extractionAttempted = false;
      _extractedPlaying = false;
    });
    unawaited(_hub.stop(PlaybackSessionId.extractPayload));

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
    Uint8List? imageBytes;
    String? status;
    if (error != null) {
      status = error;
    } else if (payload == null) {
      status = s.keyMismatch;
    } else if (payload.imageBytes != null) {
      imageBytes = payload.imageBytes;
      status = null;
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

    final succeeded = (text != null && text.isNotEmpty) ||
        audio != null ||
        imageBytes != null;

    setState(() {
      _processing = false;
      _extractionAttempted = true;
      _result = text;
      _extractedAudio = audio;
      _extractedImageBytes = imageBytes;
      _statusMessage = status;
      _extractInputHidden = succeeded;
    });

    if (succeeded) {
      await _showExtractCompleteDialog();
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

  Future<void> _showExtractCompleteDialog() async {
    if (!mounted) return;
    final s = AppStrings.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(s.extractCompleteTitle),
          content: Text(
            s.operationSuccess,
            textAlign: TextAlign.center,
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

  Future<void> _playLoaded() async {
    final wav = _loadedWav;
    if (wav == null) return;
    try {
      await _hub.playIfNotPlaying(PlaybackSessionId.extractCover, wav);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
    }
  }

  Future<void> _pauseLoaded() async {
    try {
      await _hub.pause(PlaybackSessionId.extractCover);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
    }
  }

  Future<void> _stopLoaded() async {
    try {
      await _hub.stop(PlaybackSessionId.extractCover);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
    }
  }

  String _resultBody(AppStrings s) {
    if (_extractedImageBytes != null) return s.extractedImage;
    if (_extractedAudio != null) return s.extractedAudio;
    if (_result != null && _result!.isNotEmpty) return _result!;
    if (_result != null && _result!.isEmpty) return s.noText;
    return _statusMessage ?? s.noText;
  }

  bool get _extractSucceeded =>
      (_result != null && _result!.isNotEmpty) ||
      _extractedAudio != null ||
      _extractedImageBytes != null;

  bool get _hasLoadedAudio => _loadedWav != null;

  bool get _canStartNewExtract =>
      _extractInputHidden ||
      _loadedWav != null ||
      _bitLenCtrl.text.trim().isNotEmpty ||
      _extractionAttempted ||
      _result != null ||
      _extractedAudio != null ||
      _extractedImageBytes != null ||
      _statusMessage != null ||
      _coverPlaying ||
      _coverLoaded ||
      _extractedPlaying;

  bool get _newExtractFabEnabled {
    if (_processing || _loadingFile) return false;
    return _extractInputHidden || _canStartNewExtract;
  }

  Future<void> _startNewExtract() async {
    if (!_newExtractFabEnabled) return;
    try {
      await _hub.stopSessions(PlaybackHub.extractSessions);
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
      _extractInputHidden = false;
      _loadedWav = null;
      _result = null;
      _extractedAudio = null;
      _extractedImageBytes = null;
      _statusMessage = null;
      _bitLengthError = null;
      _coverPlaying = false;
      _coverLoaded = false;
      _extractedPlaying = false;
    });
    if (_scrollCtrl.hasClients) {
      unawaited(
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  Future<void> _playExtractedAudio() async {
    final wav = _extractedAudio;
    if (wav == null) return;
    try {
      await _hub.playOrToggle(
        PlaybackSessionId.extractPayload,
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

  Future<void> _saveExtractedImage() async {
    final imageBytes = _extractedImageBytes;
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
        fileName: 'extracted_payload.$ext',
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

  Widget _buildNewExtractFab(AppStrings s) {
    return PageToolbarFab(
      tooltip: s.extractNew,
      icon: Icons.note_add_outlined,
      onPressed: _newExtractFabEnabled ? _startNewExtract : null,
      primary: true,
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
    return PageToolbarFab(
      tooltip: s.helpTooltip,
      icon: Icons.help_outline_rounded,
      onPressed: () =>
          showHelpSheet(context, initialSection: HelpSection.extract),
      primary: false,
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
    final scheme = Theme.of(context).colorScheme;
    final useFixedLen = ref.watch(settingsProvider).defaultFixedMessageBitLimit;
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
                  _buildNewExtractFab(s),
                  const SizedBox(width: AppUiTokens.toolbarFabGap),
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
              if (!_extractInputHidden) ...[
                AudioFileDropSurface(
                  enabled: !_processing && !_loadingFile,
                  onFilePath: (path) => unawaited(
                    _loadAudioFile(fileName: p.basename(path), path: path),
                  ),
                  child: AppSectionCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.audio_file_outlined,
                          size: 56,
                          color: scheme.primary,
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
                            enabled: !_processing && !_loadingFile,
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
                              icon: const Icon(Icons.folder_open),
                              label: Text(s.pickFile),
                            ),
                            _buildPlaybackControls(s),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _processing ||
                                  _loadingFile ||
                                  !_hasLoadedAudio
                              ? null
                              : _extract,
                          icon: const Icon(Icons.lock_open_outlined),
                          label: Text(s.extractTab),
                        ),
                        if (_statusMessage != null &&
                            !_processing &&
                            !_loadingFile) ...[
                          const SizedBox(height: 12),
                          Text(
                            _statusMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppUiTokens.sectionGap),
              ],
              KeyedSubtree(key: _resultCardKey, child: _resultCard(s)),
            ],
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
    final scheme = theme.colorScheme;
    final gap = AppUiTokens.sectionGapResult;
    final isAudio = _extractedAudio != null;
    final isImage = _extractedImageBytes != null;
    final ok = _extractSucceeded;
    final payloadTitle = isImage
        ? s.extractedImage
        : (isAudio ? s.extractedAudio : s.extractedText);

    return AppSectionCard(
      outlined: ok,
      color: ok ? null : scheme.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExtractHero(s, theme, scheme, ok, payloadTitle),
          if (ok) ...[
            SizedBox(height: gap),
            _buildExtractActions(s, isAudio: isAudio, isImage: isImage),
            SizedBox(height: gap),
            _buildExtractPayloadBlock(
              s,
              theme,
              scheme,
              isAudio: isAudio,
              isImage: isImage,
              payloadTitle: payloadTitle,
            ),
          ] else ...[
            SizedBox(height: gap),
            Text(
              _resultBody(s),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractHero(
    AppStrings s,
    ThemeData theme,
    ColorScheme scheme,
    bool ok,
    String payloadTitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: ok
              ? scheme.primary.withValues(alpha: 0.92)
              : scheme.onErrorContainer,
          size: AppUiTokens.resultHeroIconSize,
        ),
        const SizedBox(height: 8),
        Text(
          ok ? s.operationSuccess : payloadTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: ok ? scheme.onSurface : scheme.onErrorContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (ok) ...[
          const SizedBox(height: 4),
          Text(
            s.extractSuccessSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExtractActions(
    AppStrings s, {
    required bool isAudio,
    required bool isImage,
  }) {
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
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          if (isImage)
            Tooltip(
              message: s.saveExtractedImage,
              child: IconButton.filled(
                onPressed: _saveExtractedImage,
                icon: const Icon(Icons.save_outlined),
              ),
            )
          else if (isAudio) ...[
            Tooltip(
              message: s.saveExtractedAudio,
              child: IconButton.filled(
                onPressed: _saveExtractedAudio,
                icon: const Icon(Icons.save_outlined),
              ),
            ),
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
          ] else
            Builder(
              builder: (innerCtx) {
                return Tooltip(
                  message: s.copy,
                  child: IconButton.filled(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(innerCtx);
                      await Clipboard.setData(
                        ClipboardData(text: _result!),
                      );
                      messenger.showSnackBar(
                        SnackBar(content: Text(s.copied)),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExtractPayloadBlock(
    AppStrings s,
    ThemeData theme,
    ColorScheme scheme, {
    required bool isAudio,
    required bool isImage,
    required String payloadTitle,
  }) {
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppUiTokens.resultBlockRadius),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              payloadTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (isImage)
              ClipRRect(
                borderRadius: AppUiTokens.imageBorderRadius,
                child: Image.memory(
                  _extractedImageBytes!,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              )
            else if (isAudio)
              Text(
                _resultBody(s),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                ),
              )
            else
              DirectionalSelectableText(
                _resultBody(s),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
