import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Writes [bytes] to a temp file so native share sheets receive a real path.
Future<XFile> wavXFileFromBytes(Uint8List bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final path = p.join(dir.path, fileName);
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return XFile(path, name: fileName, mimeType: 'audio/wav');
}
