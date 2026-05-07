import 'dart:typed_data';

import '../../audio/wav_io.dart';
import '../crypto/logistic_map.dart';
import '../text/text_codec.dart';

/// Result of an LSB embed operation.
class LsbEmbedResult {
  final WavFile stego;
  final int bitsEmbedded;
  final int capacityBits;

  const LsbEmbedResult({
    required this.stego,
    required this.bitsEmbedded,
    required this.capacityBits,
  });
}

/// Result of an LSB extract operation.
class LsbExtractResult {
  final String? text;
  final int bitsRead;

  const LsbExtractResult({required this.text, required this.bitsRead});
}

/// LSB + Logistic-Chaos audio steganography — direct port of
/// `Matlab/embed_extract_data.m`.
///
/// MATLAB pseudocode:
/// ```matlab
/// encrypted = xor(msg, key);
/// stego_int(i) = bitset(cover_int(i), 1, encrypted(i));   % LSB write
/// extracted_enc(i) = bitget(stego_int(i), 1);             % LSB read
/// extracted = xor(extracted_enc, key);
/// ```
///
/// The Dart equivalent for `bitset(x,1,b)` is `(x & ~1) | b`, and
/// `bitget(x,1)` is `x & 1`.
class LsbCodec {
  final double r;
  final double x0;

  const LsbCodec({this.r = 3.99, this.x0 = 0.45});

  /// Embeds [text] into [cover].
  ///
  /// Throws [ArgumentError] if [text] needs more bits than the cover provides.
  LsbEmbedResult embedText(WavFile cover, String text) {
    final bits = TextCodec.encodeToBits(text);
    return _embedBits(cover, bits);
  }

  /// Extracts text from a stego WAV file. Returns `null` text if invalid.
  LsbExtractResult extractText(WavFile stego) {
    final samples = stego.toMono().samples;
    final available = samples.length;
    if (available < TextCodec.headerBits) {
      return const LsbExtractResult(text: null, bitsRead: 0);
    }
    final headerBits = _readEncryptedBits(samples, TextCodec.headerBits);
    final headerKey =
        LogisticMap.binaryKey(length: TextCodec.headerBits, x0: x0, r: r);
    var length = 0;
    for (var i = 0; i < TextCodec.headerBits; i++) {
      final bit = (headerBits[i] ^ headerKey[i]) & 1;
      length = (length << 1) | bit;
    }
    final totalBits = TextCodec.headerBits + length * 8;
    if (length < 0 || totalBits > available) {
      return LsbExtractResult(text: null, bitsRead: TextCodec.headerBits);
    }
    final encrypted = _readEncryptedBits(samples, totalBits);
    final fullKey = LogisticMap.binaryKey(length: totalBits, x0: x0, r: r);
    final decrypted = Uint8List(totalBits);
    for (var i = 0; i < totalBits; i++) {
      decrypted[i] = (encrypted[i] ^ fullKey[i]) & 1;
    }
    final text = TextCodec.decodeFromBits(decrypted);
    return LsbExtractResult(text: text, bitsRead: totalBits);
  }

  LsbEmbedResult _embedBits(WavFile cover, Uint8List bits) {
    final mono = cover.toMono();
    final capacity = mono.samples.length;
    if (bits.length > capacity) {
      throw ArgumentError(
          'Message too long: needs ${bits.length} bits, capacity $capacity');
    }
    final key = LogisticMap.binaryKey(length: bits.length, x0: x0, r: r);
    final out = Int16List.fromList(mono.samples);
    for (var i = 0; i < bits.length; i++) {
      final encrypted = (bits[i] ^ key[i]) & 1;
      final v = out[i];
      out[i] = ((v & ~1) | encrypted).toSigned(16);
    }
    return LsbEmbedResult(
      stego: WavFile(
        sampleRate: mono.sampleRate,
        numChannels: 1,
        bitsPerSample: 16,
        samples: out,
      ),
      bitsEmbedded: bits.length,
      capacityBits: capacity,
    );
  }

  Uint8List _readEncryptedBits(Int16List samples, int count) {
    final out = Uint8List(count);
    for (var i = 0; i < count; i++) {
      out[i] = samples[i] & 1;
    }
    return out;
  }
}
