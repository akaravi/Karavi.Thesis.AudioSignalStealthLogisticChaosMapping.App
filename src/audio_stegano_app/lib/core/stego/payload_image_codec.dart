import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'payload_envelope.dart';

/// Compresses a user-picked still image into a JPEG body that fits the
/// ASTG bit budget (long-edge shrink + quality ladder).
abstract final class PayloadImageCodec {
  /// Returns JPEG bytes sized for [bitBudget], or throws if even the smallest
  /// attempt exceeds the budget.
  static Uint8List compressToFitBudget(
    Uint8List sourceBytes, {
    required int bitBudget,
  }) {
    final maxBytes = PayloadImageDefaults.maxImageBytesForBitBudget(bitBudget);
    if (maxBytes < 64) {
      throw StateError('Bit budget too small for an image payload');
    }

    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw const FormatException('Unsupported or corrupt image file');
    }

    var working = decoded;
    final longEdge = working.width > working.height ? working.width : working.height;
    if (longEdge > PayloadImageDefaults.maxLongEdgePx) {
      working = img.copyResize(
        working,
        width: working.width >= working.height
            ? PayloadImageDefaults.maxLongEdgePx
            : null,
        height: working.height > working.width
            ? PayloadImageDefaults.maxLongEdgePx
            : null,
        interpolation: img.Interpolation.average,
      );
    }

    for (var edge = PayloadImageDefaults.maxLongEdgePx;
        edge >= 64;
        edge = (edge * 0.75).round().clamp(64, PayloadImageDefaults.maxLongEdgePx)) {
      var candidate = working;
      final currentLong =
          candidate.width > candidate.height ? candidate.width : candidate.height;
      if (currentLong > edge) {
        candidate = img.copyResize(
          working,
          width: working.width >= working.height ? edge : null,
          height: working.height > working.width ? edge : null,
          interpolation: img.Interpolation.average,
        );
      }

      for (var q = PayloadImageDefaults.jpegQuality;
          q >= PayloadImageDefaults.minJpegQuality;
          q -= 10) {
        final jpeg = Uint8List.fromList(
          img.encodeJpg(candidate, quality: q),
        );
        if (jpeg.length <= maxBytes) {
          return jpeg;
        }
      }
    }

    throw StateError(
      'Image cannot be compressed under the bit budget ($maxBytes bytes)',
    );
  }
}
