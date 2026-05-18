/// Public API of the steganography module.
///
/// **فایل اصلی الگوریتم:** [audio_watermarking.dart]
///
/// ```dart
/// import 'package:audio_steg_app/core/stego/stego.dart';
/// // یا مستقیم:
/// import 'package:audio_steg_app/core/stego/audio_watermarking.dart';
///
/// const wm = AudioWatermarking();
/// final outcome = wm.embed(text: 'پیام', cover: wav);
/// ```
library;

export 'audio_watermarking.dart';
export 'engine/stego_runner.dart';
