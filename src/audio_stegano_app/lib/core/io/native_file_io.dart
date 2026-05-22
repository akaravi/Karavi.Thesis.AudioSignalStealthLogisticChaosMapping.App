import 'dart:io';
import 'dart:typed_data';

Future<void> nativeWriteBytes(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes);
}

bool nativeFileExists(String path) => File(path).existsSync();

Future<Uint8List> nativeReadBytes(String path) async {
  return File(path).readAsBytes();
}
