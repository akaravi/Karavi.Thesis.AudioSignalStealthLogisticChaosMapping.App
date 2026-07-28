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
import '../../app/app_icon_accents.dart';
import '../../app/busy_overlay_provider.dart';
import '../../app/opened_audio_file.dart';
import '../../app/pending_open_audio_provider.dart';
import '../../app/settings_controller.dart';
import '../../core/audio/audio_input_loader.dart';
import '../../core/audio/audio_load_errors.dart';
import '../../core/audio/playback_hub.dart';
import '../../core/audio/wav_io.dart';
import '../../core/stego/stego.dart';
import '../shared/accent_icon.dart';
import '../shared/audio_file_drop_surface.dart';
import '../shared/app_section_card.dart';
import '../shared/directional_selectable_text.dart';
import '../shared/directional_text_field.dart';
import '../shared/help_sheet.dart';
import '../shared/page_app_bar.dart';
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

  /// After a successful extract, pick/load card stays hidden until New.
  /// Derived from result payloads so UI cannot desync with the result card.
  bool get _extractInputHidden =>
      _extractedAudio != null ||
      _extractedImageBytes != null ||
      (_result != null && _result!.isNotEmpty);
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
      await _hub.playOrToggle(PlaybackSessionId.extractCover, wav);
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AccentActionIconButton(
          tooltip: s.play,
          icon: Icons.play_arrow_rounded,
          accent: AppIconAccent.play,
          filled: true,
          onPressed: _processing || _coverPlaying ? null : _playLoaded,
        ),
        const SizedBox(width: 8),
        AccentActionIconButton(
          tooltip: s.pause,
          icon: Icons.pause_rounded,
          accent: AppIconAccent.pause,
          onPressed: _processing || !_coverPlaying ? null : _pauseLoaded,
        ),
        const SizedBox(width: 8),
        AccentActionIconButton(
          tooltip: s.stopPlayback,
          icon: Icons.stop_rounded,
          accent: AppIconAccent.stop,
          onPressed: _processing || !_coverLoaded ? null : _stopLoaded,
        ),
      ],
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
    return Scaffold(
      appBar: PageAppBar(
        title: s.extractTab,
        actions: [
          _buildNewExtractFab(s),
          _buildHelpFab(s),
        ],
      ),
      body: TabScrollBody(
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
                        AccentGlowIcon(
                          Icons.audio_file_outlined,
                          accent: AppIconAccent.audio,
                          size: 30,
                          tileSize: 56,
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
                              prefixIcon: AccentIcon(
                                Icons.format_list_numbered,
                                accent: AppIconAccent.list,
                              ),
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
                              style: FilledButton.styleFrom(
                                backgroundColor: AppIconAccents.foreground(
                                  AppIconAccent.folder,
                                  Theme.of(context).brightness,
                                ),
                                foregroundColor: AppIconAccents.onFill(
                                  Theme.of(context).brightness,
                                ),
                              ),
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
                          style: FilledButton.styleFrom(
                            backgroundColor: AppIconAccents.foreground(
                              AppIconAccent.unlock,
                              Theme.of(context).brightness,
                            ),
                            foregroundColor: AppIconAccents.onFill(
                              Theme.of(context).brightness,
                            ),
                          ),
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
        if (ok)
          AccentGlowIcon(
            Icons.check_circle_rounded,
            accent: AppIconAccent.verify,
            size: 30,
            tileSize: AppUiTokens.resultHeroIconSize + 24,
          )
        else
          AccentGlowIcon(
            Icons.error_outline_rounded,
            accent: AppIconAccent.stop,
            size: 30,
            tileSize: AppUiTokens.resultHeroIconSize + 24,
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.center,
      children: [
        if (isImage)
          AccentActionIconButton(
            tooltip: s.saveExtractedImage,
            icon: Icons.save_outlined,
            accent: AppIconAccent.save,
            filled: true,
            onPressed: _saveExtractedImage,
          )
        else if (isAudio)
          AccentActionIconButton(
            tooltip: s.saveExtractedAudio,
            icon: Icons.save_outlined,
            accent: AppIconAccent.save,
            filled: true,
            onPressed: _saveExtractedAudio,
          )
        else
          Builder(
            builder: (innerCtx) {
              return AccentActionIconButton(
                tooltip: s.copy,
                icon: Icons.copy_outlined,
                accent: AppIconAccent.copy,
                filled: true,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(innerCtx);
                  await Clipboard.setData(
                    ClipboardData(text: _result!),
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
              isAudio ? s.extractListenTitle : payloadTitle,
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
              _buildExtractListenSides(s, theme, scheme)
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

  Widget _buildExtractListenSides(
    AppStrings s,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final coverTransport =
        _coverPlaying || _hub.isPaused(PlaybackSessionId.extractCover);
    final extractedTransport =
        _extractedPlaying || _hub.isPaused(PlaybackSessionId.extractPayload);

    Widget sideCard({
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
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onPlay,
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(playing ? s.pause : playLabel),
                ),
                if (showTransport) ...[
                  IconButton.filledTonal(
                    tooltip: s.pause,
                    onPressed: onPause,
                    icon: const Icon(Icons.pause_rounded, size: 18),
                  ),
                  IconButton.filledTonal(
                    tooltip: s.stopPlayback,
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_rounded, size: 18),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    final carrierCard = sideCard(
      badge: 'A',
      title: s.extractCarrierShort,
      playLabel: s.playCarrierAudio,
      playing: _coverPlaying,
      showTransport: coverTransport,
      emphasized: false,
      onPlay: _hasLoadedAudio ? _playLoaded : null,
      onPause: coverTransport ? _pauseLoaded : null,
      onStop: coverTransport || _coverLoaded ? _stopLoaded : null,
    );
    final extractedCard = sideCard(
      badge: 'B',
      title: s.extractedAudio,
      playLabel: s.playExtractedAudio,
      playing: _extractedPlaying,
      showTransport: extractedTransport,
      emphasized: true,
      onPlay: _extractedAudio != null ? _playExtractedAudio : null,
      onPause: extractedTransport
          ? () => unawaited(_hub.pause(PlaybackSessionId.extractPayload))
          : null,
      onStop: extractedTransport || _extractedPlaying
          ? () => unawaited(_hub.stop(PlaybackSessionId.extractPayload))
          : null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= AppUiTokens.resultContentBreakpoint;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: carrierCard),
              const SizedBox(width: 8),
              Expanded(child: extractedCard),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            carrierCard,
            const SizedBox(height: 8),
            extractedCard,
          ],
        );
      },
    );
  }
}
