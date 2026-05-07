import 'dart:convert';
import 'dart:typed_data';

/// Converts between UTF-8 text and bit streams (Uint8List of 0/1).
/// Uses a 32-bit big-endian header to encode the byte length, so the decoder
/// knows where the message ends.
class TextCodec {
  static const int headerBits = 32;

  /// Encodes [text] as a header(32-bit length) + UTF-8 payload, expressed as
  /// a Uint8List of bits (each element is 0 or 1, MSB-first within each byte).
  static Uint8List encodeToBits(String text) {
    final bytes = utf8.encode(text);
    final length = bytes.length;
    final totalBits = headerBits + bytes.length * 8;
    final out = Uint8List(totalBits);

    for (var i = 0; i < headerBits; i++) {
      out[i] = (length >> (headerBits - 1 - i)) & 1;
    }
    var pos = headerBits;
    for (final b in bytes) {
      for (var bit = 7; bit >= 0; bit--) {
        out[pos++] = (b >> bit) & 1;
      }
    }
    return out;
  }

  /// Decodes the bit stream produced by [encodeToBits].
  /// Returns null if the embedded length exceeds the available bits.
  static String? decodeFromBits(Uint8List bits) {
    if (bits.length < headerBits) return null;
    var length = 0;
    for (var i = 0; i < headerBits; i++) {
      length = (length << 1) | (bits[i] & 1);
    }
    final payloadBits = length * 8;
    if (length < 0 || headerBits + payloadBits > bits.length) {
      return null;
    }
    final bytes = Uint8List(length);
    var pos = headerBits;
    for (var i = 0; i < length; i++) {
      var b = 0;
      for (var bit = 0; bit < 8; bit++) {
        b = (b << 1) | (bits[pos++] & 1);
      }
      bytes[i] = b;
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return null;
    }
  }

  /// Total bits required to embed [text].
  static int requiredBits(String text) =>
      headerBits + utf8.encode(text).length * 8;
}
