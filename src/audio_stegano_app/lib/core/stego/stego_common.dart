import 'dart:convert';
import 'dart:typed_data';

import 'message_block_autoencoder.dart';

/// پیش‌فرض‌ها — `main_steganography.m`
const double kWatermarkDefaultR = 3.99;
const double kWatermarkDefaultX0 = 0.45;

/// پارامترهای مشترک `embed_message.m` / `extract_message.m`
class StegoMessageContext {
  final double r;
  final double x0;
  final MessageBlockAutoencoder autoencoder;

  const StegoMessageContext({
    this.r = kWatermarkDefaultR,
    this.x0 = kWatermarkDefaultX0,
    required this.autoencoder,
  });

  /// اتوانکدر → XOR با کلید لاجستیک — `embed_mode = ae_xor`
  Uint8List buildPayload(Uint8List binaryMsg, Uint8List key) {
    final encoded = autoencoder.encodeRounded(binaryMsg);
    return MessageBlockAutoencoder.buildPayload(encoded, key);
  }

  /// `round(net(...))` پس از XOR — `extract_message.m`
  Uint8List recoverMessageBits(Uint8List payload) =>
      autoencoder.decodeBits(payload);
}

/// `train/stego_common.m` — message_to_bits / bits_to_message
class MessageBits {
  static Uint8List fromUtf8Text(String text) {
    final bytes = utf8.encode(text);
    final out = Uint8List(bytes.length * 8);
    var pos = 0;
    for (final b in bytes) {
      for (var bit = 7; bit >= 0; bit--) {
        out[pos++] = (b >> bit) & 1;
      }
    }
    return out;
  }

  static String? toUtf8Text(Uint8List bits) {
    if (bits.isEmpty) return '';
    if (bits.length % 8 != 0) return null;
    final bytes = Uint8List(bits.length ~/ 8);
    var pos = 0;
    for (var i = 0; i < bytes.length; i++) {
      var b = 0;
      for (var bit = 0; bit < 8; bit++) {
        b = (b << 1) | (bits[pos++] & 1);
      }
      bytes[i] = b;
    }
    var end = bytes.length;
    while (end > 0 && bytes[end - 1] == 0) {
      end--;
    }
    if (end == 0) return '';
    try {
      return utf8.decode(bytes.sublist(0, end));
    } on FormatException {
      return null;
    }
  }

  static int bitLengthForText(String text) => fromUtf8Text(text).length;

  static Uint8List fromUtf8TextPadded(String text, int fixedBitLength) {
    final bits = fromUtf8Text(text);
    if (bits.length > fixedBitLength) {
      throw ArgumentError(
        'Message needs ${bits.length} bits; fixed limit is $fixedBitLength.',
      );
    }
    if (bits.length == fixedBitLength) return bits;
    final padded = Uint8List(fixedBitLength);
    padded.setRange(0, bits.length, bits);
    return padded;
  }
}

Int16List toMatlabInt16(Int16List samples) {
  final out = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    final normalized = samples[i] / 32767.0;
    var v = (normalized * 32767).round();
    if (v > 32767) v = 32767;
    if (v < -32768) v = -32768;
    out[i] = v;
  }
  return out;
}
