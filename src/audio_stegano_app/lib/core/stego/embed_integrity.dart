/// Post-embed integrity: stego must recover the exact original payload bits
/// and differ from cover only in intended LSBs.
library;

import 'dart:typed_data';

import '../audio/wav_io.dart';
import 'extract_message.dart';
import 'logistic_positions.dart';
import 'message_block_autoencoder.dart';
import 'payload_envelope.dart';
import 'stego_common.dart';

/// Result of [EmbedIntegrity.verify].
class EmbedIntegrityResult {
  final bool ok;
  final String? failureReason;

  const EmbedIntegrityResult.ok()
      : ok = true,
        failureReason = null;

  const EmbedIntegrityResult.fail(this.failureReason) : ok = false;
}

/// Immediate round-trip / cover-fidelity checks after LSB embed.
abstract final class EmbedIntegrity {
  /// Verifies in-memory extract bits, cover vs stego LSB-only diff,
  /// WAV encode→decode→extract, and typed payload equality.
  static EmbedIntegrityResult verify({
    required WavFile cover,
    required WavFile stego,
    required Uint8List originalBits,
    required Uint8List extractedBits,
    required double berPercent,
    required double r,
    required double x0,
    required MessageBlockAutoencoder autoencoder,
  }) {
    if (berPercent != 0.0) {
      return EmbedIntegrityResult.fail(
        'BER is $berPercent% (must be 0 after embed)',
      );
    }
    if (extractedBits.length != originalBits.length) {
      return const EmbedIntegrityResult.fail(
        'Extracted bit length does not match embedded bits',
      );
    }
    for (var i = 0; i < originalBits.length; i++) {
      if ((extractedBits[i] & 1) != (originalBits[i] & 1)) {
        return EmbedIntegrityResult.fail('Bit mismatch at index $i');
      }
    }

    final coverMono = toMatlabInt16(cover.toMono().samples);
    final stegoMono = stego.toMono().samples;
    if (coverMono.length != stegoMono.length) {
      return const EmbedIntegrityResult.fail(
        'Stego length differs from cover (mono)',
      );
    }
    final positions = LogisticPositions.compute(
      n: originalBits.length,
      maxPos: coverMono.length,
      x0: x0,
      r: r,
    );
    final posSet = positions.toSet();
    for (var i = 0; i < coverMono.length; i++) {
      if (posSet.contains(i)) {
        if ((coverMono[i] & ~1) != (stegoMono[i] & ~1)) {
          return EmbedIntegrityResult.fail(
            'Non-LSB sample changed at index $i',
          );
        }
      } else if (coverMono[i] != stegoMono[i]) {
        return EmbedIntegrityResult.fail(
          'Cover sample altered outside embed positions at $i',
        );
      }
    }

    late final Uint8List afterWav;
    try {
      final reloaded = WavFile.decode(stego.encode());
      final extract = ExtractMessage(r: r, x0: x0, autoencoder: autoencoder);
      final bits = extract.runBits(
        stego: reloaded,
        msgBitLength: originalBits.length,
      );
      if (bits == null) {
        return const EmbedIntegrityResult.fail(
          'Extract after WAV encode/decode returned null',
        );
      }
      afterWav = bits;
    } catch (e) {
      return EmbedIntegrityResult.fail('WAV round-trip extract failed: $e');
    }
    for (var i = 0; i < originalBits.length; i++) {
      if ((afterWav[i] & 1) != (originalBits[i] & 1)) {
        return const EmbedIntegrityResult.fail(
          'Payload bits corrupted after WAV encode/decode',
        );
      }
    }

    final expected = PayloadEnvelope.unpackBits(originalBits);
    final recovered = PayloadEnvelope.unpackBits(afterWav);
    if (expected.type != recovered.type ||
        expected.isLegacy != recovered.isLegacy) {
      return const EmbedIntegrityResult.fail(
        'Recovered payload type does not match original',
      );
    }
    if (expected.text != null && expected.text != recovered.text) {
      return EmbedIntegrityResult.fail(
        'Recovered text does not match original (got: ${recovered.text})',
      );
    }
    if (expected.audio != null) {
      final a = expected.audio!;
      final b = recovered.audio;
      if (b == null ||
          a.sampleRate != b.sampleRate ||
          a.samples.length != b.samples.length) {
        return const EmbedIntegrityResult.fail(
          'Recovered audio meta does not match original payload',
        );
      }
      for (var i = 0; i < a.samples.length; i++) {
        if (a.samples[i] != b.samples[i]) {
          return EmbedIntegrityResult.fail(
            'Recovered audio sample mismatch at $i',
          );
        }
      }
    }

    return const EmbedIntegrityResult.ok();
  }

  static void assertOk(EmbedIntegrityResult result) {
    if (!result.ok) {
      throw StateError(
        result.failureReason ?? 'Embed integrity check failed',
      );
    }
  }
}
