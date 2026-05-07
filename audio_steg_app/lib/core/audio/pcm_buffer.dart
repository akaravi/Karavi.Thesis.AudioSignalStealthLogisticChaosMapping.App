import 'dart:typed_data';

/// Helpers to convert between raw PCM byte streams and Int16/Float64 buffers.
class PcmBuffer {
  /// Converts little-endian 16-bit signed PCM bytes to [Int16List].
  static Int16List bytesToInt16(Uint8List bytes) {
    final out = Int16List(bytes.length ~/ 2);
    final bd = ByteData.sublistView(bytes);
    for (var i = 0; i < out.length; i++) {
      out[i] = bd.getInt16(i * 2, Endian.little);
    }
    return out;
  }

  static Uint8List int16ToBytes(Int16List samples) {
    final out = Uint8List(samples.length * 2);
    final bd = ByteData.sublistView(out);
    for (var i = 0; i < samples.length; i++) {
      bd.setInt16(i * 2, samples[i], Endian.little);
    }
    return out;
  }

  /// Resamples mono Int16 PCM by simple linear interpolation. Returns the
  /// original buffer if [from] equals [to].
  static Int16List resampleMono(Int16List samples, int from, int to) {
    if (from == to) return samples;
    final ratio = from / to;
    final outLen = (samples.length / ratio).floor();
    final out = Int16List(outLen);
    for (var i = 0; i < outLen; i++) {
      final src = i * ratio;
      final i0 = src.floor();
      final i1 = (i0 + 1).clamp(0, samples.length - 1);
      final frac = src - i0;
      final v = samples[i0] * (1 - frac) + samples[i1] * frac;
      out[i] = v.round().clamp(-32768, 32767);
    }
    return out;
  }
}
