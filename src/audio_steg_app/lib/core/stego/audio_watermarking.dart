/// هستهٔ نهان‌نگاری صوتی — پورت مستقیم از اسکریپت‌های MATLAB.
///
/// منبع:
///   • `logistic_map_keygen.m`
///   • `embed_extract_data.m`
///   • `evaluate_stego.m`
///   • `main_steganography.m`
///
/// استفاده در هر جای پروژه:
/// ```dart
/// import 'package:audio_steg_app/core/stego/audio_watermarking.dart';
///
/// const wm = AudioWatermarking(r: 3.99, x0: 0.45);
/// final outcome = wm.embed(text: 'پیام', cover: wavFile);
/// final text = wm.extract(stego: outcome.stego, msgBitLength: outcome.bitsEmbedded);
/// ```
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../audio/wav_io.dart';

// ─── Defaults (main_steganography.m) ───────────────────────────────────────

const double kWatermarkDefaultR = 3.99;
const double kWatermarkDefaultX0 = 0.45;

// ─── logistic_map_keygen.m ─────────────────────────────────────────────────

/// تولید کلید آشوب لاجستیک — `Matlab/logistic_map_keygen.m`.
class LogisticMap {
  static const double defaultR = kWatermarkDefaultR;
  static const double defaultX0 = kWatermarkDefaultX0;

  static Float64List sequence({
    required int length,
    double x0 = defaultX0,
    double r = defaultR,
  }) {
    if (length <= 0) return Float64List(0);
    if (x0 <= 0.0 || x0 >= 1.0) {
      throw ArgumentError('x0 must be in (0,1), got $x0');
    }
    if (r <= 0.0 || r > 4.0) {
      throw ArgumentError('r must be in (0,4], got $r');
    }
    final out = Float64List(length);
    out[0] = r * x0 * (1.0 - x0);
    for (var i = 1; i < length; i++) {
      final prev = out[i - 1];
      out[i] = r * prev * (1.0 - prev);
    }
    return out;
  }

  static Uint8List binaryKey({
    required int length,
    double x0 = defaultX0,
    double r = defaultR,
  }) {
    final seq = sequence(length: length, x0: x0, r: r);
    if (seq.isEmpty) return Uint8List(0);
    var sum = 0.0;
    for (final v in seq) {
      sum += v;
    }
    final threshold = sum / seq.length;
    final key = Uint8List(length);
    for (var i = 0; i < length; i++) {
      key[i] = seq[i] >= threshold ? 1 : 0;
    }
    return key;
  }
}

// ─── Message bits (UI helper for main_steganography binary_msg) ────────────

/// تبدیل متن به بیت خام (بدون فریم اضافی خارج از متلب).
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
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return null;
    }
  }

  static int bitLengthForText(String text) => fromUtf8Text(text).length;
}

// ─── evaluate_stego.m ──────────────────────────────────────────────────────

/// معیارهای ارزیابی — `Matlab/evaluate_stego.m`.
class WatermarkMetrics {
  final double snrDb;
  final double psnrDb;
  final double berPercent;
  final double npcrPercent;
  final double uaciPercent;

  const WatermarkMetrics({
    required this.snrDb,
    required this.psnrDb,
    required this.berPercent,
    required this.npcrPercent,
    required this.uaciPercent,
  });

  factory WatermarkMetrics.evaluate({
    required Int16List cover,
    required Int16List stego,
    required Uint8List originalBits,
    required Uint8List extractedBits,
    required Int16List stegoWithDiffKey,
  }) {
    final n = math.min(cover.length, stego.length);
    final x = Float64List(n);
    final y = Float64List(n);
    for (var i = 0; i < n; i++) {
      x[i] = cover[i] / 32767.0;
      y[i] = stego[i] / 32767.0;
    }

    var signalPower = 0.0;
    var noisePower = 0.0;
    for (var i = 0; i < n; i++) {
      signalPower += x[i] * x[i];
      final d = x[i] - y[i];
      noisePower += d * d;
    }

    final snr = noisePower == 0
        ? double.infinity
        : 10 * (math.log(signalPower / noisePower) / math.ln10);
    final mse = noisePower / n;
    final psnr = mse == 0
        ? double.infinity
        : 10 * (math.log(1.0 / mse) / math.ln10);

    final m = math.min(originalBits.length, extractedBits.length);
    var errors = 0;
    for (var i = 0; i < m; i++) {
      if ((originalBits[i] & 1) != (extractedBits[i] & 1)) errors++;
    }
    final ber = m == 0 ? 0.0 : (errors / m) * 100.0;

    final len = math.min(n, stegoWithDiffKey.length);
    var diffCount = 0;
    var absSum = 0.0;
    for (var i = 0; i < len; i++) {
      final y1 = stego[i] / 32767.0;
      final y2 = stegoWithDiffKey[i] / 32767.0;
      if (y1 != y2) diffCount++;
      absSum += (y1 - y2).abs();
    }
    final npcr = len == 0 ? 0.0 : (diffCount / len) * 100.0;
    final uaci = len == 0 ? 0.0 : (absSum / (len * 2.0)) * 100.0;

    return WatermarkMetrics(
      snrDb: snr,
      psnrDb: psnr,
      berPercent: ber,
      npcrPercent: npcr,
      uaciPercent: uaci,
    );
  }
}

// ─── Results ───────────────────────────────────────────────────────────────

/// خروجی `embed_extract_data.m`.
class WatermarkEmbedResult {
  final WavFile stego;
  final Uint8List extractedBits;
  final int bitsEmbedded;
  final int capacityBits;

  const WatermarkEmbedResult({
    required this.stego,
    required this.extractedBits,
    required this.bitsEmbedded,
    required this.capacityBits,
  });

  /// نام قدیمی فیلد — سازگاری با کد قبلی.
  Uint8List get extractedMsg => extractedBits;
}

/// خروجی کامل جریان `main_steganography.m`.
class WatermarkOutcome {
  final WavFile stego;
  final WatermarkMetrics metrics;
  final int bitsEmbedded;
  final int capacityBits;
  final Uint8List originalBits;
  final Uint8List extractedBits;

  const WatermarkOutcome({
    required this.stego,
    required this.metrics,
    required this.bitsEmbedded,
    required this.capacityBits,
    required this.originalBits,
    required this.extractedBits,
  });
}

// ─── embed_extract_data.m + main_steganography.m ─────────────────────────

/// API واحد نهان‌نگاری صوتی LSB + آشوب لاجستیک.
class AudioWatermarking {
  final double r;
  final double x0;

  const AudioWatermarking({
    this.r = kWatermarkDefaultR,
    this.x0 = kWatermarkDefaultX0,
  });

  // ── Embed + evaluate (main_steganography.m) ─────────────────────────────

  WatermarkOutcome embed({required String text, required WavFile cover}) {
    final binaryMsg = MessageBits.fromUtf8Text(text);
    final embed = embedBits(cover: cover, binaryMsg: binaryMsg);
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

  /// استخراج متن؛ [msgBitLength] همان `msg_len` در متلب.
  String? extract({required WavFile stego, required int msgBitLength}) {
    return extractText(stego: stego, msgBitLength: msgBitLength);
  }

  // ── embed_extract_data.m ────────────────────────────────────────────────

  WatermarkEmbedResult embedText({
    required WavFile cover,
    required String text,
  }) {
    return embedBits(cover: cover, binaryMsg: MessageBits.fromUtf8Text(text));
  }

  WatermarkEmbedResult embedBits({
    required WavFile cover,
    required Uint8List binaryMsg,
    Uint8List? binKey,
  }) {
    final key =
        binKey ?? LogisticMap.binaryKey(length: binaryMsg.length, x0: x0, r: r);
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

    final coverInt = _toMatlabInt16(mono.samples);
    final stegoInt = Int16List.fromList(coverInt);
    final extracted = Uint8List(binaryMsg.length);

    for (var i = 0; i < binaryMsg.length; i++) {
      final encrypted = (binaryMsg[i] ^ key[i]) & 1;
      final v = stegoInt[i];
      stegoInt[i] = ((v & ~1) | encrypted).toSigned(16);
      extracted[i] = ((stegoInt[i] & 1) ^ key[i]) & 1;
    }

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

  Uint8List? extractBits({
    required WavFile stego,
    required int msgBitLength,
    Uint8List? binKey,
  }) {
    if (msgBitLength <= 0) return Uint8List(0);
    final samples = stego.toMono().samples;
    if (msgBitLength > samples.length) return null;

    final key =
        binKey ?? LogisticMap.binaryKey(length: msgBitLength, x0: x0, r: r);

    final extracted = Uint8List(msgBitLength);
    for (var i = 0; i < msgBitLength; i++) {
      final enc = samples[i] & 1;
      extracted[i] = (enc ^ key[i]) & 1;
    }
    return extracted;
  }

  String? extractText({required WavFile stego, required int msgBitLength}) {
    final bits = extractBits(stego: stego, msgBitLength: msgBitLength);
    if (bits == null) return null;
    return MessageBits.toUtf8Text(bits);
  }

  /// استگو با کلید `x0 + 1e-10` برای NPCR/UACI در `evaluate_stego.m`.
  WavFile stegoWithPerturbedKey({
    required WavFile cover,
    required Uint8List binaryMsg,
  }) {
    final key = LogisticMap.binaryKey(
      length: binaryMsg.length,
      x0: x0 + 1e-10,
      r: r,
    );
    final mono = cover.toMono();
    final coverInt = _toMatlabInt16(mono.samples);
    final stegoInt = Int16List.fromList(coverInt);

    for (var i = 0; i < binaryMsg.length; i++) {
      final encrypted = (binaryMsg[i] ^ key[i]) & 1;
      final v = stegoInt[i];
      stegoInt[i] = ((v & ~1) | encrypted).toSigned(16);
    }

    return WavFile(
      sampleRate: mono.sampleRate,
      numChannels: 1,
      bitsPerSample: 16,
      samples: stegoInt,
    );
  }

  static Int16List _toMatlabInt16(Int16List samples) {
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
}

// ─── نام‌های سازگار با کد قبلی ───────────────────────────────────────────

typedef StegoMetrics = WatermarkMetrics;
typedef EmbedOutcome = WatermarkOutcome;
typedef LsbEmbedResult = WatermarkEmbedResult;

/// نتیجه استخراج — API قدیمی.
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

/// Wrapper با امضای positional برای کد و تست‌های قدیمی.
@Deprecated('Use AudioWatermarking with named parameters')
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

@Deprecated('Use AudioWatermarking')
class StegoEngine {
  final AudioWatermarking _core;

  StegoEngine({double r = kWatermarkDefaultR, double x0 = kWatermarkDefaultX0})
    : _core = AudioWatermarking(r: r, x0: x0);

  WatermarkOutcome embed({required String text, required WavFile cover}) =>
      _core.embed(text: text, cover: cover);

  String? extract(WavFile stego, int msgBitLength) =>
      _core.extract(stego: stego, msgBitLength: msgBitLength);
}
