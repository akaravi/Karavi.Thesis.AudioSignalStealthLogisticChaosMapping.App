import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Opens the platform share sheet (Share Center on mobile).
Future<void> shareStegoWavBytes({
  required Uint8List bytes,
  required String fileName,
  required String subject,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, name: fileName, mimeType: 'audio/wav')],
      fileNameOverrides: [fileName],
      subject: subject,
      text: subject,
    ),
  );
}

Future<void> shareRecoveryBitsText(String text) async {
  await SharePlus.instance.share(ShareParams(text: text));
}
