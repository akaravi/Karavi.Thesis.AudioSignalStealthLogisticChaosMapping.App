import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/platform/platform.dart';
import 'wav_xfile.dart';

/// How share completed when the platform sheet is unavailable.
enum StegoShareOutcome {
  /// Native / Web Share API (or equivalent) was used.
  shared,

  /// Fallback: WAV saved/downloaded via system file dialog.
  fileDownloaded,

  /// Text was copied to the clipboard instead of a share sheet.
  textCopied,
}

/// Share stego WAV: mobile/desktop use OS share sheet; web triggers download.
Future<StegoShareOutcome> shareStegoWavBytes({
  required Uint8List bytes,
  required String fileName,
  required String subject,
}) async {
  if (kIsWeb) {
    return _downloadWavFallback(bytes, fileName);
  }

  final xFile = await wavXFileFromBytes(bytes, fileName);
  try {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        fileNameOverrides: [fileName],
        subject: subject,
      ),
    );
    if (result.status == ShareResultStatus.dismissed) {
      throw StateError('Share dismissed');
    }
    if (result.status == ShareResultStatus.unavailable) {
      return _downloadWavFallback(bytes, fileName);
    }
    return StegoShareOutcome.shared;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('shareStegoWavBytes: $e\n$st');
    }
    if (isMobilePlatform) rethrow;
    return _downloadWavFallback(bytes, fileName);
  }
}

Future<StegoShareOutcome> shareRecoveryBitsText(String text) async {
  if (kIsWeb) {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, mailToFallbackEnabled: true),
      );
      if (result.status != ShareResultStatus.dismissed) {
        return StegoShareOutcome.shared;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('shareRecoveryBitsText web: $e\n$st');
      }
    }
    await Clipboard.setData(ClipboardData(text: text));
    return StegoShareOutcome.textCopied;
  }

  try {
    final result = await SharePlus.instance.share(
      ShareParams(text: text, mailToFallbackEnabled: true),
    );
    if (result.status == ShareResultStatus.dismissed) {
      throw StateError('Share dismissed');
    }
    return StegoShareOutcome.shared;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('shareRecoveryBitsText: $e\n$st');
    }
    await Clipboard.setData(ClipboardData(text: text));
    return StegoShareOutcome.textCopied;
  }
}

Future<StegoShareOutcome> _downloadWavFallback(
  Uint8List bytes,
  String fileName,
) async {
  final saved = await FilePicker.saveFile(
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['wav'],
    bytes: bytes,
  );
  if (kIsWeb || saved != null) {
    return StegoShareOutcome.fileDownloaded;
  }
  throw StateError('Share cancelled');
}
