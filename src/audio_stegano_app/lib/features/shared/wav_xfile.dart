import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'wav_xfile_io.dart' if (dart.library.html) 'wav_xfile_web.dart' as impl;

Future<XFile> wavXFileFromBytes(Uint8List bytes, String fileName) =>
    impl.wavXFileFromBytes(bytes, fileName);
