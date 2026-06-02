/// جاسازی پیام مخفی — پورت `train/embed_message.m`
///
/// ```dart
/// import 'package:audio_stegano_app/core/stego/embed_message.dart';
///
/// final embed = EmbedMessage(r: 3.99, x0: 0.45);
/// final result = embed.runBits(cover: wav, binaryMsg: bits);
/// ```
library;

import 'dart:typed_data';

import '../audio/wav_io.dart';
import 'evaluate_stego.dart';
import 'logistic_map_keygen.dart';
import 'logistic_positions.dart';
import 'message_block_autoencoder.dart';
import 'stego_common.dart';
import 'stego_embed_mode.dart';

/// `train/embed_message.m`
class EmbedMessage {
  final StegoMessageContext ctx;

  EmbedMessage({
    double r = kWatermarkDefaultR,
    double x0 = kWatermarkDefaultX0,
    StegoEmbedMode embedMode = StegoEmbedMode.xorOnly,
    MessageBlockAutoencoder? autoencoder,
  }) : ctx = StegoMessageContext(
         r: r,
         x0: x0,
         embedMode: embedMode,
         autoencoder: autoencoder,
       );

  /// متن → بیت → (اتوانکدر اختیاری) → XOR → LSB در `logistic_positions`
  WatermarkEmbedResult runText({
    required WavFile cover,
    required String text,
  }) {
    return runBits(cover: cover, binaryMsg: MessageBits.fromUtf8Text(text));
  }

  WatermarkEmbedResult runBits({
    required WavFile cover,
    required Uint8List binaryMsg,
    Uint8List? binKey,
  }) {
    final key =
        binKey ??
        LogisticMap.binaryKey(length: binaryMsg.length, x0: ctx.x0, r: ctx.r);
    if (key.length != binaryMsg.length) {
      throw ArgumentError('binKey length must match binaryMsg');
    }

    final mono = cover.toMono();
    final capacity = mono.samples.length;
    if (binaryMsg.length > capacity) {
      throw ArgumentError(
        'Message too long: needs ${binaryMsg.length} bits, capacity $capacity',
      );
    }

    final coverInt = toMatlabInt16(mono.samples);
    final stegoInt = Int16List.fromList(coverInt);
    final positions = LogisticPositions.compute(
      n: binaryMsg.length,
      maxPos: capacity,
      x0: ctx.x0,
      r: ctx.r,
    );
    final payload = ctx.buildPayload(binaryMsg, key);

    for (var i = 0; i < binaryMsg.length; i++) {
      final idx = positions[i];
      final encrypted = payload[i] & 1;
      final v = stegoInt[idx];
      stegoInt[idx] = ((v & ~1) | encrypted).toSigned(16);
    }

    final payloadFromStego = Uint8List(binaryMsg.length);
    for (var i = 0; i < binaryMsg.length; i++) {
      payloadFromStego[i] = ((stegoInt[positions[i]] & 1) ^ key[i]) & 1;
    }
    final extracted = ctx.recoverMessageBits(payloadFromStego);

    return WatermarkEmbedResult(
      stego: WavFile(
        sampleRate: mono.sampleRate,
        numChannels: 1,
        bitsPerSample: 16,
        samples: stegoInt,
      ),
      extractedBits: extracted,
      bitsEmbedded: binaryMsg.length,
      capacityBits: capacity,
    );
  }

  /// بازیابی در حافظه — همان `extract_payload_from_int` در انتهای `embed_message.m`
  Uint8List verifyInMemory({
    required Int16List stegoInt,
    required List<int> positions,
    required Uint8List key,
    required int msgLength,
  }) {
    final payload = Uint8List(msgLength);
    for (var i = 0; i < msgLength; i++) {
      payload[i] = ((stegoInt[positions[i]] & 1) ^ key[i]) & 1;
    }
    return ctx.recoverMessageBits(payload);
  }

  /// استگو با کلید `x0 + 1e-10` برای NPCR/UACI (`evaluate_stego.m`)
  WavFile stegoWithPerturbedKey({
    required WavFile cover,
    required Uint8List binaryMsg,
  }) {
    final key = LogisticMap.binaryKey(
      length: binaryMsg.length,
      x0: ctx.x0 + 1e-10,
      r: ctx.r,
    );
    final mono = cover.toMono();
    final coverInt = toMatlabInt16(mono.samples);
    final stegoInt = Int16List.fromList(coverInt);
    final positions = LogisticPositions.compute(
      n: binaryMsg.length,
      maxPos: mono.samples.length,
      x0: ctx.x0 + 1e-10,
      r: ctx.r,
    );
    final payload = ctx.buildPayload(binaryMsg, key);

    for (var i = 0; i < binaryMsg.length; i++) {
      final idx = positions[i];
      final encrypted = payload[i] & 1;
      final v = stegoInt[idx];
      stegoInt[idx] = ((v & ~1) | encrypted).toSigned(16);
    }

    return WavFile(
      sampleRate: mono.sampleRate,
      numChannels: 1,
      bitsPerSample: 16,
      samples: stegoInt,
    );
  }

  /// embed + متریک — `main_steganography.m`
  WatermarkOutcome runWithMetrics({
    required String text,
    required WavFile cover,
    int? fixedMsgBitLength,
  }) {
    final binaryMsg = fixedMsgBitLength != null && fixedMsgBitLength > 0
        ? MessageBits.fromUtf8TextPadded(text, fixedMsgBitLength)
        : MessageBits.fromUtf8Text(text);
    final embed = runBits(cover: cover, binaryMsg: binaryMsg);
    final stegoDiff = stegoWithPerturbedKey(cover: cover, binaryMsg: binaryMsg);
    final coverMono = cover.toMono();

    final metrics = WatermarkMetrics.evaluate(
      cover: coverMono.samples,
      stego: embed.stego.samples,
      originalBits: binaryMsg,
      extractedBits: embed.extractedBits,
      stegoWithDiffKey: stegoDiff.samples,
    );

    return WatermarkOutcome(
      stego: embed.stego,
      metrics: metrics,
      bitsEmbedded: embed.bitsEmbedded,
      capacityBits: embed.capacityBits,
      originalBits: binaryMsg,
      extractedBits: embed.extractedBits,
    );
  }
}
