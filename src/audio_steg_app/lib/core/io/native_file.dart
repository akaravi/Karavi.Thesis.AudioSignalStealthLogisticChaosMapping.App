import 'dart:typed_data';

import 'native_file_io.dart'
    if (dart.library.html) 'native_file_web.dart'
    as impl;

Future<void> nativeWriteBytes(String path, Uint8List bytes) =>
    impl.nativeWriteBytes(path, bytes);

bool nativeFileExists(String path) => impl.nativeFileExists(path);

Future<Uint8List> nativeReadBytes(String path) => impl.nativeReadBytes(path);
