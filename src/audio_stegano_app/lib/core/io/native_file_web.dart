import 'dart:typed_data';

Future<void> nativeWriteBytes(String path, Uint8List bytes) async {
  throw UnsupportedError('Filesystem paths are not available on web');
}

bool nativeFileExists(String path) => false;

Future<Uint8List> nativeReadBytes(String path) async {
  throw UnsupportedError('Filesystem paths are not available on web');
}
