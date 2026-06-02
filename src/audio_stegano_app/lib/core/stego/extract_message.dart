/// استخراج پیام مخفی — پورت `train/extract_message.m`
///
/// ```dart
/// import 'package:audio_stegano_app/core/stego/extract_message.dart';
///
/// final extract = ExtractMessage(r: 3.99, x0: 0.45);
/// final text = extract.runText(stego: wav, msgBitLength: msgLen);
/// ```
library;

import 'dart:typed_data';

import '../audio/wav_io.dart';
import 'logistic_map_keygen.dart';
import 'logistic_positions.dart';
import 'message_block_autoencoder.dart';
import 'stego_common.dart';

/// `train/extract_message.m`
class ExtractMessage {
  final StegoMessageContext ctx;

  ExtractMessage({
    double r = kWatermarkDefaultR,
    double x0 = kWatermarkDefaultX0,
    required MessageBlockAutoencoder autoencoder,
  }) : ctx = StegoMessageContext(
         r: r,
         x0: x0,
         autoencoder: autoencoder,
       );

  /// `msg_length` همان `stego_meta.msg_length` در متلب
  String? runText({
    required WavFile stego,
    required int msgBitLength,
    Uint8List? binKey,
  }) {
    final bits = runBits(
      stego: stego,
      msgBitLength: msgBitLength,
      binKey: binKey,
    );
    if (bits == null) return null;
    return MessageBits.toUtf8Text(bits);
  }

  Uint8List? runBits({
    required WavFile stego,
    required int msgBitLength,
    Uint8List? binKey,
  }) {
    if (msgBitLength <= 0) return Uint8List(0);
    final samples = stego.toMono().samples;
    if (msgBitLength > samples.length) return null;

    final key =
        binKey ??
        LogisticMap.binaryKey(length: msgBitLength, x0: ctx.x0, r: ctx.r);
    final positions = LogisticPositions.compute(
      n: msgBitLength,
      maxPos: samples.length,
      x0: ctx.x0,
      r: ctx.r,
    );

    final payload = Uint8List(msgBitLength);
    for (var i = 0; i < msgBitLength; i++) {
      final enc = samples[positions[i]] & 1;
      payload[i] = (enc ^ key[i]) & 1;
    }
    return ctx.recoverMessageBits(payload);
  }
}
