/// نقطهٔ ورود یکپارچه — نام‌های MATLAB: [embed_message], [extract_message]
///
/// ```dart
/// import 'package:audio_stegano_app/core/stego/embed_message.dart';
/// import 'package:audio_stegano_app/core/stego/extract_message.dart';
/// ```
library;

export 'embed_message.dart';
export 'evaluate_stego.dart';
export 'extract_message.dart';
export 'logistic_map_keygen.dart';
export 'logistic_positions.dart';
export 'message_block_autoencoder.dart';
export 'stego_common.dart';
export 'stego_embed_mode.dart';
export 'trained_autoencoder_loader.dart';

import 'dart:typed_data';

import '../audio/wav_io.dart';
import 'embed_message.dart';
import 'evaluate_stego.dart';
import 'extract_message.dart';
import 'message_block_autoencoder.dart';
import 'stego_common.dart';
import 'stego_embed_mode.dart';

/// API سازگار با کد قبلی — دروناً از [EmbedMessage] و [ExtractMessage] استفاده می‌کند.
class AudioWatermarking {
  final EmbedMessage _embed;
  final ExtractMessage _extract;

  double get r => _embed.ctx.r;
  double get x0 => _embed.ctx.x0;
  StegoEmbedMode get embedMode => _embed.ctx.embedMode;
  MessageBlockAutoencoder? get autoencoder => _embed.ctx.autoencoder;

  AudioWatermarking({
    double r = kWatermarkDefaultR,
    double x0 = kWatermarkDefaultX0,
    StegoEmbedMode embedMode = StegoEmbedMode.xorOnly,
    MessageBlockAutoencoder? autoencoder,
  })  : _embed = EmbedMessage(
          r: r,
          x0: x0,
          embedMode: embedMode,
          autoencoder: autoencoder,
        ),
        _extract = ExtractMessage(
          r: r,
          x0: x0,
          embedMode: embedMode,
          autoencoder: autoencoder,
        );

  WatermarkOutcome embed({
    required String text,
    required WavFile cover,
    int? fixedMsgBitLength,
  }) =>
      _embed.runWithMetrics(
        text: text,
        cover: cover,
        fixedMsgBitLength: fixedMsgBitLength,
      );

  String? extract({required WavFile stego, required int msgBitLength}) =>
      _extract.runText(stego: stego, msgBitLength: msgBitLength);

  WatermarkEmbedResult embedText({
    required WavFile cover,
    required String text,
  }) =>
      _embed.runText(cover: cover, text: text);

  WatermarkEmbedResult embedBits({
    required WavFile cover,
    required Uint8List binaryMsg,
    Uint8List? binKey,
  }) =>
      _embed.runBits(cover: cover, binaryMsg: binaryMsg, binKey: binKey);

  Uint8List? extractBits({
    required WavFile stego,
    required int msgBitLength,
    Uint8List? binKey,
  }) =>
      _extract.runBits(
        stego: stego,
        msgBitLength: msgBitLength,
        binKey: binKey,
      );

  String? extractText({required WavFile stego, required int msgBitLength}) =>
      extract(stego: stego, msgBitLength: msgBitLength);

  WavFile stegoWithPerturbedKey({
    required WavFile cover,
    required Uint8List binaryMsg,
  }) =>
      _embed.stegoWithPerturbedKey(cover: cover, binaryMsg: binaryMsg);
}

typedef StegoMetrics = WatermarkMetrics;
typedef EmbedOutcome = WatermarkOutcome;
typedef LsbEmbedResult = WatermarkEmbedResult;

class LsbExtractResult {
  final Uint8List? bits;
  final String? text;
  final int bitsRead;

  const LsbExtractResult({
    required this.bits,
    required this.text,
    required this.bitsRead,
  });
}

@Deprecated('Use EmbedMessage / ExtractMessage')
class LsbCodec {
  final AudioWatermarking _core;

  LsbCodec({double r = kWatermarkDefaultR, double x0 = kWatermarkDefaultX0})
    : _core = AudioWatermarking(r: r, x0: x0);

  WatermarkEmbedResult embedText(WavFile cover, String text) =>
      _core.embedText(cover: cover, text: text);

  LsbExtractResult extractText(WavFile stego, int msgBitLength) {
    final bits = _core.extractBits(stego: stego, msgBitLength: msgBitLength);
    if (bits == null) {
      return const LsbExtractResult(bits: null, text: null, bitsRead: 0);
    }
    return LsbExtractResult(
      bits: bits,
      text: MessageBits.toUtf8Text(bits),
      bitsRead: bits.length,
    );
  }

  WatermarkEmbedResult embedBits(WavFile cover, Uint8List binaryMsg) =>
      _core.embedBits(cover: cover, binaryMsg: binaryMsg);

  Uint8List? extractBits(WavFile stego, int msgBitLength) =>
      _core.extractBits(stego: stego, msgBitLength: msgBitLength);

  WavFile stegoWithPerturbedKey(WavFile cover, Uint8List binaryMsg) =>
      _core.stegoWithPerturbedKey(cover: cover, binaryMsg: binaryMsg);
}

@Deprecated('Use EmbedMessage / ExtractMessage')
class StegoEngine {
  final AudioWatermarking _core;

  StegoEngine({double r = kWatermarkDefaultR, double x0 = kWatermarkDefaultX0})
    : _core = AudioWatermarking(r: r, x0: x0);

  WatermarkOutcome embed({required String text, required WavFile cover}) =>
      _core.embed(text: text, cover: cover);

  String? extract(WavFile stego, int msgBitLength) =>
      _core.extract(stego: stego, msgBitLength: msgBitLength);
}
