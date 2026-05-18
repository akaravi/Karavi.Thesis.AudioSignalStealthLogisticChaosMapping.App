import 'dart:typed_data';

/// Minimal RIFF/WAVE reader & writer for PCM 16-bit Mono.
///
/// We deliberately implement this from scratch to keep full control over the
/// LSB layout (any external library could re-quantize and corrupt our data).
class WavFile {
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;

  /// PCM samples as signed 16-bit integers, interleaved if stereo.
  final Int16List samples;

  WavFile({
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
    required this.samples,
  });

  bool get isPcm16Mono => bitsPerSample == 16 && numChannels == 1;

  /// Parses a WAV file's bytes. Supports PCM (format 1) at 16-bit only,
  /// mono or stereo, 8000–192000 Hz.
  factory WavFile.decode(Uint8List bytes) {
    if (bytes.length < 44) {
      throw const FormatException('WAV too short (<44 bytes)');
    }
    final bd = ByteData.sublistView(bytes);

    String tag(int offset) =>
        String.fromCharCodes(bytes.sublist(offset, offset + 4));

    if (tag(0) != 'RIFF' || tag(8) != 'WAVE') {
      throw const FormatException('Not a RIFF/WAVE file');
    }

    var pos = 12;
    int? sampleRate;
    int? numChannels;
    int? bitsPerSample;
    int? formatTag;
    Int16List? samples;

    while (pos + 8 <= bytes.length) {
      final chunkId = tag(pos);
      final chunkSize = bd.getUint32(pos + 4, Endian.little);
      final dataStart = pos + 8;
      if (chunkId == 'fmt ') {
        formatTag = bd.getUint16(dataStart, Endian.little);
        numChannels = bd.getUint16(dataStart + 2, Endian.little);
        sampleRate = bd.getUint32(dataStart + 4, Endian.little);
        bitsPerSample = bd.getUint16(dataStart + 14, Endian.little);
      } else if (chunkId == 'data') {
        if (bitsPerSample == null || formatTag == null) {
          throw const FormatException('data chunk before fmt chunk');
        }
        if (formatTag != 1) {
          throw FormatException('Only PCM (1) supported, got $formatTag');
        }
        if (bitsPerSample != 16) {
          throw FormatException(
              'Only 16-bit PCM supported, got $bitsPerSample-bit');
        }
        final sampleCount = chunkSize ~/ 2;
        samples = Int16List(sampleCount);
        for (var i = 0; i < sampleCount; i++) {
          samples[i] = bd.getInt16(dataStart + i * 2, Endian.little);
        }
      }
      pos = dataStart + chunkSize + (chunkSize.isOdd ? 1 : 0);
    }

    if (sampleRate == null ||
        numChannels == null ||
        bitsPerSample == null ||
        samples == null) {
      throw const FormatException('Missing fmt or data chunk');
    }

    return WavFile(
      sampleRate: sampleRate,
      numChannels: numChannels,
      bitsPerSample: bitsPerSample,
      samples: samples,
    );
  }

  /// Encodes back to a RIFF/WAVE PCM byte buffer.
  Uint8List encode() {
    final dataSize = samples.length * (bitsPerSample ~/ 8);
    final fmtChunkSize = 16;
    final riffSize = 4 + (8 + fmtChunkSize) + (8 + dataSize);
    final out = Uint8List(8 + riffSize);
    final bd = ByteData.sublistView(out);

    void writeTag(int offset, String tag) {
      for (var i = 0; i < 4; i++) {
        out[offset + i] = tag.codeUnitAt(i);
      }
    }

    writeTag(0, 'RIFF');
    bd.setUint32(4, riffSize, Endian.little);
    writeTag(8, 'WAVE');

    writeTag(12, 'fmt ');
    bd.setUint32(16, fmtChunkSize, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, numChannels, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    bd.setUint32(28, byteRate, Endian.little);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    bd.setUint16(32, blockAlign, Endian.little);
    bd.setUint16(34, bitsPerSample, Endian.little);

    writeTag(36, 'data');
    bd.setUint32(40, dataSize, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      bd.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return out;
  }

  /// Returns a copy converted to mono 16-bit by averaging channels if needed.
  WavFile toMono() {
    if (numChannels == 1) return this;
    final mono = Int16List(samples.length ~/ numChannels);
    for (var i = 0; i < mono.length; i++) {
      var sum = 0;
      for (var c = 0; c < numChannels; c++) {
        sum += samples[i * numChannels + c];
      }
      mono[i] = (sum ~/ numChannels).clamp(-32768, 32767);
    }
    return WavFile(
      sampleRate: sampleRate,
      numChannels: 1,
      bitsPerSample: bitsPerSample,
      samples: mono,
    );
  }
}
