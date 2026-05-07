/// Public API of the steganography module.
///
/// Folder layout:
/// ```
/// core/stego/
/// ├── stego.dart              <- this barrel
/// ├── crypto/   logistic_map.dart   (chaotic key generator)
/// ├── text/     text_codec.dart     (UTF-8 ↔ bit stream)
/// ├── codecs/   lsb_codec.dart      (digital LSB + Chaos — MATLAB port)
/// │             fsk_codec.dart      (over-the-air BFSK + Chaos + Hamming + CRC)
/// ├── engine/   stego_engine.dart   (Strategy facade)
/// │             stego_runner.dart   (Isolate runner via compute())
/// └── metrics/  metrics.dart        (SNR / PSNR / BER)
/// ```
///
/// Consumers should import only this file:
/// ```dart
/// import 'package:audio_steg_app/core/stego/stego.dart';
/// ```
library;

export 'codecs/fsk_codec.dart';
export 'codecs/lsb_codec.dart';
export 'crypto/logistic_map.dart';
export 'engine/stego_engine.dart';
export 'engine/stego_runner.dart';
export 'metrics/metrics.dart';
export 'text/text_codec.dart';
