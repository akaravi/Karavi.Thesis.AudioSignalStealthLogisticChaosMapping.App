import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<XFile> wavXFileFromBytes(Uint8List bytes, String fileName) async {
  return XFile.fromData(bytes, name: fileName, mimeType: 'audio/wav');
}
