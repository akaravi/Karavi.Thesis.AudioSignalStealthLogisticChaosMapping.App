import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_strings.dart';
import '../../app/settings_controller.dart';
import '../../core/audio/wav_io.dart';
import '../../core/stego/stego.dart';

class ExtractScreen extends ConsumerStatefulWidget {
  const ExtractScreen({super.key});

  @override
  ConsumerState<ExtractScreen> createState() => _ExtractScreenState();
}

class _ExtractScreenState extends ConsumerState<ExtractScreen> {
  final _bitLenCtrl = TextEditingController();
  bool _processing = false;
  String? _result;
  String? _statusMessage;

  @override
  void dispose() {
    _bitLenCtrl.dispose();
    super.dispose();
  }

  int? _parseBitLength(AppStrings s) {
    final raw = _bitLenCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _statusMessage = s.errorBitLengthEmpty);
      return null;
    }
    final n = int.tryParse(raw);
    if (n == null || n <= 0) {
      setState(() => _statusMessage = s.errorBitLengthInvalid);
      return null;
    }
    return n;
  }

  Future<void> _pickAndExtract() async {
    if (_processing) return;
    final s = AppStrings.of(context);
    final msgBitLength = _parseBitLength(s);
    if (msgBitLength == null) return;

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

    final wavBytes = bytes;
    if (wavBytes == null) return;

    String? text;
    String? error;
    try {
      final wav = WavFile.decode(wavBytes);
      final settings = ref.read(settingsProvider);
      text = await StegoRunner.extract(
        wav,
        msgBitLength: msgBitLength,
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bitLenCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: !_processing,
                    decoration: InputDecoration(
                      labelText: s.msgBitLengthHint,
                      helperText: s.msgBitLengthHelper,
                      prefixIcon: const Icon(Icons.format_list_numbered),
                    ),
                  ),
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
                Icon(
                  _result != null
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                ),
                const SizedBox(width: 8),
                Text(
                  s.extractedText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
                child: Builder(
                  builder: (innerCtx) {
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
