import 'dart:typed_data';

import 'wav_io.dart';

Future<WavFile> decodeMp3FromPath(String inputPath) {
  throw UnsupportedError('decodeMp3FromPath is not available on web');
}

Future<WavFile> decodeMp3BytesViaTempFile(Uint8List mp3Bytes) {
  throw UnsupportedError('decodeMp3BytesViaTempFile is not available on web');
}
