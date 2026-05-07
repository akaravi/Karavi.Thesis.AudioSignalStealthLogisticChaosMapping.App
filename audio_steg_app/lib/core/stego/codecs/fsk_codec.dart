import 'dart:math' as math;
import 'dart:typed_data';

import '../crypto/logistic_map.dart';
import '../text/text_codec.dart';

/// Robust audio data link based on Binary FSK (BFSK) modulation +
/// Logistic-Chaos XOR + Hamming(7,4) ECC + CRC-16 framing + chirp preamble.
///
/// Design choices (tuned for hostile speaker→air→microphone path):
///   * Sample rate           : 44100 Hz
///   * Mark frequency  (f1)  : 2200 Hz
///   * Space frequency (f0)  : 1200 Hz
///   * Baud rate             : 50  (samples per symbol = 882)
///   * Preamble              : 100 ms chirp 800 → 3000 Hz
///
/// Frame layout (after chaos XOR is applied to the *plaintext* bits):
///     [Hamming-encoded header (32 bits → 56 bits)]
///     [Hamming-encoded payload bytes (8 bits each → 14 bits each)]
///     [CRC-16/CCITT over plaintext header+payload, encoded with Hamming]
class FskCodec {
  static const int sampleRate = 44100;
  static const double markHz = 2200.0;
  static const double spaceHz = 1200.0;
  static const int baud = 50;
  static const double preambleStartHz = 800.0;
  static const double preambleEndHz = 3000.0;
  static const double preambleSeconds = 0.1;
  static const double trailingSilenceSeconds = 0.05;

  final double r;
  final double x0;

  const FskCodec({this.r = 3.99, this.x0 = 0.45});

  int get samplesPerSymbol => sampleRate ~/ baud;

  /// Encodes [text] to a 16-bit PCM mono Float64-normalized buffer.
  Float64List modulate(String text) {
    final plain = TextCodec.encodeToBits(text);
    final crcBits = _crc16Bits(plain);
    final framed = Uint8List(plain.length + crcBits.length)
      ..setRange(0, plain.length, plain)
      ..setRange(plain.length, plain.length + crcBits.length, crcBits);

    final key = LogisticMap.binaryKey(length: framed.length, x0: x0, r: r);
    final encrypted = Uint8List(framed.length);
    for (var i = 0; i < framed.length; i++) {
      encrypted[i] = (framed[i] ^ key[i]) & 1;
    }

    final ecc = _hammingEncode(encrypted);

    final preamble = _chirp(
      durationSeconds: preambleSeconds,
      f0: preambleStartHz,
      f1: preambleEndHz,
    );
    final symbol = samplesPerSymbol;
    final payload = Float64List(ecc.length * symbol);
    var phase = 0.0;
    for (var i = 0; i < ecc.length; i++) {
      final freq = ecc[i] == 1 ? markHz : spaceHz;
      final dPhase = 2 * math.pi * freq / sampleRate;
      for (var j = 0; j < symbol; j++) {
        payload[i * symbol + j] = math.sin(phase);
        phase += dPhase;
        if (phase > 2 * math.pi) phase -= 2 * math.pi;
      }
    }

    final tail = Float64List((trailingSilenceSeconds * sampleRate).round());
    final out = Float64List(preamble.length + payload.length + tail.length);
    out.setAll(0, preamble);
    out.setAll(preamble.length, payload);
    return out;
  }

  /// Demodulates a Float64 buffer (normalized -1..+1) back to text. Returns
  /// `null` on CRC failure.
  String? demodulate(Float64List signal) {
    final start = _findPreamble(signal);
    if (start < 0) return null;
    final pos = start;
    final symbol = samplesPerSymbol;
    final maxSymbols = (signal.length - pos) ~/ symbol;
    if (maxSymbols < 56) return null;
    final ecc = Uint8List(maxSymbols);
    for (var i = 0; i < maxSymbols; i++) {
      final off = pos + i * symbol;
      final mark = _goertzel(signal, off, symbol, markHz);
      final space = _goertzel(signal, off, symbol, spaceHz);
      ecc[i] = mark > space ? 1 : 0;
    }

    final encrypted = _hammingDecode(ecc);
    if (encrypted.length < TextCodec.headerBits + 16) return null;

    final headerKey =
        LogisticMap.binaryKey(length: TextCodec.headerBits, x0: x0, r: r);
    var length = 0;
    for (var i = 0; i < TextCodec.headerBits; i++) {
      length = (length << 1) | ((encrypted[i] ^ headerKey[i]) & 1);
    }
    final plainBits = TextCodec.headerBits + length * 8;
    final framedBits = plainBits + 16;
    if (framedBits > encrypted.length || length < 0 || length > 1 << 20) {
      return null;
    }

    final key = LogisticMap.binaryKey(length: framedBits, x0: x0, r: r);
    final framed = Uint8List(framedBits);
    for (var i = 0; i < framedBits; i++) {
      framed[i] = (encrypted[i] ^ key[i]) & 1;
    }
    final plain = framed.sublist(0, plainBits);
    final crcRecv = framed.sublist(plainBits);
    final crcCalc = _crc16Bits(plain);
    for (var i = 0; i < 16; i++) {
      if (crcRecv[i] != crcCalc[i]) return null;
    }
    return TextCodec.decodeFromBits(plain);
  }

  /// Convenience: convert a Float64 normalized buffer to Int16 PCM.
  static Int16List toPcm16(Float64List signal) {
    final out = Int16List(signal.length);
    for (var i = 0; i < signal.length; i++) {
      var v = (signal[i] * 32700).round();
      if (v > 32767) v = 32767;
      if (v < -32768) v = -32768;
      out[i] = v;
    }
    return out;
  }

  /// Convenience: convert Int16 PCM to normalized Float64.
  static Float64List fromPcm16(Int16List samples) {
    final out = Float64List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      out[i] = samples[i] / 32768.0;
    }
    return out;
  }

  Float64List _chirp({
    required double durationSeconds,
    required double f0,
    required double f1,
  }) {
    final n = (durationSeconds * sampleRate).round();
    final out = Float64List(n);
    final k = (f1 - f0) / durationSeconds;
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      out[i] = math.sin(2 * math.pi * (f0 * t + 0.5 * k * t * t));
    }
    return out;
  }

  /// Finds preamble start by sliding a chirp template and picking the index
  /// of maximum normalized correlation. Returns the index immediately AFTER
  /// the preamble (= start of the first data symbol).
  int _findPreamble(Float64List signal) {
    final template = _chirp(
      durationSeconds: preambleSeconds,
      f0: preambleStartHz,
      f1: preambleEndHz,
    );
    final n = template.length;
    if (signal.length < n + samplesPerSymbol) return -1;

    var templateNorm = 0.0;
    for (final v in template) {
      templateNorm += v * v;
    }
    templateNorm = math.sqrt(templateNorm);

    int searchAt(int stride, int from, int to) {
      var bIdx = -1;
      var bScore = -1.0;
      for (var i = from; i + n <= to; i += stride) {
        if (i < 0) continue;
        var dot = 0.0;
        var sigNorm = 0.0;
        for (var j = 0; j < n; j++) {
          final s = signal[i + j];
          dot += s * template[j];
          sigNorm += s * s;
        }
        sigNorm = math.sqrt(sigNorm);
        if (sigNorm == 0) continue;
        final score = dot.abs() / (sigNorm * templateNorm);
        if (score > bScore) {
          bScore = score;
          bIdx = i;
        }
      }
      return bIdx;
    }

    final coarseStride = (sampleRate / 200).round();
    final coarseIdx = searchAt(coarseStride, 0, signal.length);
    if (coarseIdx < 0) return -1;
    final fineFrom = coarseIdx - coarseStride;
    final fineTo = math.min(coarseIdx + coarseStride + n, signal.length);
    final bestIdx = searchAt(1, fineFrom, fineTo);
    if (bestIdx < 0) return -1;

    var bestScore = 0.0;
    {
      var dot = 0.0;
      var sigNorm = 0.0;
      for (var j = 0; j < n; j++) {
        final s = signal[bestIdx + j];
        dot += s * template[j];
        sigNorm += s * s;
      }
      sigNorm = math.sqrt(sigNorm);
      if (sigNorm > 0) bestScore = dot.abs() / (sigNorm * templateNorm);
    }
    if (bestScore < 0.35) return -1;
    return bestIdx + n;
  }

  double _goertzel(Float64List signal, int offset, int len, double freq) {
    final k = (0.5 + (len * freq) / sampleRate).floor();
    final w = 2 * math.pi * k / len;
    final cosw = math.cos(w);
    final coeff = 2 * cosw;
    var s0 = 0.0, s1 = 0.0, s2 = 0.0;
    for (var i = 0; i < len; i++) {
      s0 = signal[offset + i] + coeff * s1 - s2;
      s2 = s1;
      s1 = s0;
    }
    return s1 * s1 + s2 * s2 - coeff * s1 * s2;
  }

  /// CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF) over a bit stream,
  /// returns 16 bits MSB-first.
  Uint8List _crc16Bits(Uint8List bits) {
    var crc = 0xFFFF;
    for (var i = 0; i < bits.length; i++) {
      final bit = (bits[i] & 1) << 15;
      crc = (crc ^ bit) & 0xFFFF;
      if ((crc & 0x8000) != 0) {
        crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
    }
    final out = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      out[i] = (crc >> (15 - i)) & 1;
    }
    return out;
  }

  /// Encodes input bits with Hamming(7,4): every 4 input bits → 7 code bits
  /// that can correct any single-bit error. Pads to multiple of 4.
  Uint8List _hammingEncode(Uint8List bits) {
    final pad = (4 - (bits.length % 4)) % 4;
    final padded = Uint8List(bits.length + pad)..setRange(0, bits.length, bits);
    final blocks = padded.length ~/ 4;
    final out = Uint8List(blocks * 7);
    for (var b = 0; b < blocks; b++) {
      final d1 = padded[b * 4];
      final d2 = padded[b * 4 + 1];
      final d3 = padded[b * 4 + 2];
      final d4 = padded[b * 4 + 3];
      final p1 = d1 ^ d2 ^ d4;
      final p2 = d1 ^ d3 ^ d4;
      final p3 = d2 ^ d3 ^ d4;
      out[b * 7] = p1;
      out[b * 7 + 1] = p2;
      out[b * 7 + 2] = d1;
      out[b * 7 + 3] = p3;
      out[b * 7 + 4] = d2;
      out[b * 7 + 5] = d3;
      out[b * 7 + 6] = d4;
    }
    return out;
  }

  /// Decodes a Hamming(7,4) stream and corrects single-bit errors per block.
  Uint8List _hammingDecode(Uint8List ecc) {
    final blocks = ecc.length ~/ 7;
    final out = Uint8List(blocks * 4);
    for (var b = 0; b < blocks; b++) {
      var p1 = ecc[b * 7];
      var p2 = ecc[b * 7 + 1];
      var d1 = ecc[b * 7 + 2];
      var p3 = ecc[b * 7 + 3];
      var d2 = ecc[b * 7 + 4];
      var d3 = ecc[b * 7 + 5];
      var d4 = ecc[b * 7 + 6];
      final s1 = p1 ^ d1 ^ d2 ^ d4;
      final s2 = p2 ^ d1 ^ d3 ^ d4;
      final s3 = p3 ^ d2 ^ d3 ^ d4;
      final syndrome = (s3 << 2) | (s2 << 1) | s1;
      if (syndrome != 0 && syndrome <= 7) {
        final flip = syndrome - 1;
        switch (flip) {
          case 0: p1 ^= 1; break;
          case 1: p2 ^= 1; break;
          case 2: d1 ^= 1; break;
          case 3: p3 ^= 1; break;
          case 4: d2 ^= 1; break;
          case 5: d3 ^= 1; break;
          case 6: d4 ^= 1; break;
        }
      }
      out[b * 4] = d1;
      out[b * 4 + 1] = d2;
      out[b * 4 + 2] = d3;
      out[b * 4 + 3] = d4;
    }
    return out;
  }
}
