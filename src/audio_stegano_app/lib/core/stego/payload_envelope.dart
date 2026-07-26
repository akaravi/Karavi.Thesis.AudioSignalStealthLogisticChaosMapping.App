/// ASTG payload envelope — content-type header before stego body bits.
///
/// Layout (big-endian multi-byte fields):
/// `[Magic 4B "ASTG"][Ver 1B][Type 1B][Flags 2B][BodyLen u32][Body…]`
library;

import 'dart:convert';
import 'dart:typed_data';

import '../audio/wav_io.dart';
import 'stego_common.dart';

/// Content type byte in the ASTG header.
enum StegoPayloadType {
  text(0x01),
  image(0x02),
  audio(0x03),
  other(0x04);

  const StegoPayloadType(this.code);
  final int code;

  static StegoPayloadType? tryParse(int code) {
    for (final v in StegoPayloadType.values) {
      if (v.code == code) return v;
    }
    return null;
  }
}

/// Default payload voice recording parameters (lowest acceptable quality).
abstract final class PayloadAudioDefaults {
  static const int sampleRate = 8000;
  static const int channels = 1;
  static const int bitsPerSample = 8;

  /// Header(12) + audio meta(10) overhead in bytes before PCM.
  /// Meta: sampleRate u16 · ch u8 · bits u8 · numSamples u32 · peakAbs u16.
  static const int envelopeOverheadBytes = 12;
  static const int audioMetaBytes = 10;

  /// Preferred rate when exporting recovered payload for play/save.
  static const int exportSampleRate = 16000;

  static int maxPcmBytesForBitBudget(int bitBudget) {
    final maxBytes = bitBudget ~/ 8;
    final usable = maxBytes - envelopeOverheadBytes - audioMetaBytes;
    return usable < 0 ? 0 : usable;
  }

  static int maxPcmSamplesForBitBudget(int bitBudget) =>
      maxPcmBytesForBitBudget(bitBudget);

  static Duration maxDurationForBitBudget(int bitBudget) {
    final samples = maxPcmSamplesForBitBudget(bitBudget);
    return Duration(milliseconds: (samples * 1000) ~/ sampleRate);
  }
}

/// Still-image payload defaults (JPEG body under ASTG type Image).
abstract final class PayloadImageDefaults {
  static const int envelopeOverheadBytes = 12;
  static const int maxLongEdgePx = 240;
  static const int jpegQuality = 55;
  static const int minJpegQuality = 25;

  static int maxImageBytesForBitBudget(int bitBudget) {
    final maxBytes = bitBudget ~/ 8;
    final usable = maxBytes - envelopeOverheadBytes;
    return usable < 0 ? 0 : usable;
  }
}

/// Result of peeling recovered stego bits (envelope or legacy text).
class StegoPayloadResult {
  final StegoPayloadType? type;
  final bool isLegacy;
  final String? text;
  final WavFile? audio;
  /// JPEG/PNG file bytes when [type] is [StegoPayloadType.image].
  final Uint8List? imageBytes;
  final Uint8List? rawBody;

  const StegoPayloadResult({
    required this.type,
    required this.isLegacy,
    this.text,
    this.audio,
    this.imageBytes,
    this.rawBody,
  });

  factory StegoPayloadResult.legacyText(String? text) => StegoPayloadResult(
        type: StegoPayloadType.text,
        isLegacy: true,
        text: text,
      );

  factory StegoPayloadResult.text(String text) => StegoPayloadResult(
        type: StegoPayloadType.text,
        isLegacy: false,
        text: text,
      );

  factory StegoPayloadResult.audio(WavFile wav) => StegoPayloadResult(
        type: StegoPayloadType.audio,
        isLegacy: false,
        audio: wav,
      );

  factory StegoPayloadResult.image(Uint8List fileBytes) => StegoPayloadResult(
        type: StegoPayloadType.image,
        isLegacy: false,
        imageBytes: fileBytes,
      );

  factory StegoPayloadResult.unsupported(StegoPayloadType type, Uint8List body) =>
      StegoPayloadResult(
        type: type,
        isLegacy: false,
        rawBody: body,
      );
}

/// Pack / unpack ASTG envelopes and audio body codec.
abstract final class PayloadEnvelope {
  static const List<int> magicBytes = [0x41, 0x53, 0x54, 0x47]; // ASTG
  static const int version = 1;
  static const int headerByteLength = 12;
  static const int audioMetaByteLength = 10;
  static const int audioMetaByteLengthLegacy = 8;

  static bool hasMagic(Uint8List bytes) {
    if (bytes.length < 4) return false;
    for (var i = 0; i < 4; i++) {
      if (bytes[i] != magicBytes[i]) return false;
    }
    return true;
  }

  static bool hasMagicBits(Uint8List bits) {
    if (bits.length < 32) return false;
    return hasMagic(bitsToBytes(bits.sublist(0, 32)));
  }

  /// Bytes → MSB-first bit stream (0/1 per element).
  static Uint8List bytesToBits(Uint8List bytes) {
    final out = Uint8List(bytes.length * 8);
    var pos = 0;
    for (final b in bytes) {
      for (var bit = 7; bit >= 0; bit--) {
        out[pos++] = (b >> bit) & 1;
      }
    }
    return out;
  }

  /// Bit stream → bytes. Length must be a multiple of 8. Does not strip zeros.
  static Uint8List bitsToBytes(Uint8List bits) {
    if (bits.length % 8 != 0) {
      throw ArgumentError('bits length must be a multiple of 8');
    }
    final bytes = Uint8List(bits.length ~/ 8);
    var pos = 0;
    for (var i = 0; i < bytes.length; i++) {
      var b = 0;
      for (var bit = 0; bit < 8; bit++) {
        b = (b << 1) | (bits[pos++] & 1);
      }
      bytes[i] = b;
    }
    return bytes;
  }

  static Uint8List packBytes({
    required StegoPayloadType type,
    required Uint8List body,
    int flags = 0,
  }) {
    final out = Uint8List(headerByteLength + body.length);
    final bd = ByteData.sublistView(out);
    out[0] = magicBytes[0];
    out[1] = magicBytes[1];
    out[2] = magicBytes[2];
    out[3] = magicBytes[3];
    out[4] = version;
    out[5] = type.code;
    bd.setUint16(6, flags, Endian.big);
    bd.setUint32(8, body.length, Endian.big);
    out.setRange(headerByteLength, out.length, body);
    return out;
  }

  static Uint8List packBits({
    required StegoPayloadType type,
    required Uint8List body,
    int flags = 0,
    int? fixedBitLength,
  }) {
    final packed = bytesToBits(packBytes(type: type, body: body, flags: flags));
    if (fixedBitLength == null || fixedBitLength <= 0) return packed;
    if (packed.length > fixedBitLength) {
      throw ArgumentError(
        'Envelope needs ${packed.length} bits; fixed limit is $fixedBitLength.',
      );
    }
    if (packed.length == fixedBitLength) return packed;
    final padded = Uint8List(fixedBitLength);
    padded.setRange(0, packed.length, packed);
    return padded;
  }

  static Uint8List packTextBits(String text, {int? fixedBitLength}) {
    final body = Uint8List.fromList(utf8.encode(text));
    return packBits(
      type: StegoPayloadType.text,
      body: body,
      fixedBitLength: fixedBitLength,
    );
  }

  static Uint8List packAudioBits(WavFile audio, {int? fixedBitLength}) {
    final body = encodeAudioBody(audio);
    return packBits(
      type: StegoPayloadType.audio,
      body: body,
      fixedBitLength: fixedBitLength,
    );
  }

  /// Packs a still image file body (JPEG/PNG bytes) as ASTG Image.
  static Uint8List packImageBits(Uint8List imageFileBytes, {int? fixedBitLength}) {
    if (imageFileBytes.isEmpty) {
      throw ArgumentError('Image payload is empty');
    }
    if (!looksLikeImageFile(imageFileBytes)) {
      throw ArgumentError('Image payload must be JPEG or PNG');
    }
    return packBits(
      type: StegoPayloadType.image,
      body: imageFileBytes,
      fixedBitLength: fixedBitLength,
    );
  }

  static bool looksLikeImageFile(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // JPEG SOI
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;
    // PNG signature
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    return false;
  }

  /// Unpacks typed payload from recovered bits. Legacy (no magic) → UTF-8 text.
  static StegoPayloadResult unpackBits(Uint8List bits) {
    if (bits.isEmpty) {
      return StegoPayloadResult.legacyText('');
    }
    if (bits.length % 8 != 0) {
      return StegoPayloadResult.legacyText(null);
    }
    if (!hasMagicBits(bits)) {
      return StegoPayloadResult.legacyText(MessageBits.toUtf8Text(bits));
    }

    final allBytes = bitsToBytes(bits);
    if (allBytes.length < headerByteLength) {
      return StegoPayloadResult.legacyText(null);
    }
    final bd = ByteData.sublistView(allBytes);
    final ver = allBytes[4];
    if (ver != version) {
      return StegoPayloadResult.legacyText(null);
    }
    final type = StegoPayloadType.tryParse(allBytes[5]);
    if (type == null) {
      return StegoPayloadResult.legacyText(null);
    }
    final bodyLen = bd.getUint32(8, Endian.big);
    if (headerByteLength + bodyLen > allBytes.length) {
      return StegoPayloadResult.legacyText(null);
    }
    final body = allBytes.sublist(headerByteLength, headerByteLength + bodyLen);

    switch (type) {
      case StegoPayloadType.text:
        try {
          return StegoPayloadResult.text(utf8.decode(body));
        } on FormatException {
          return StegoPayloadResult.unsupported(type, body);
        }
      case StegoPayloadType.audio:
        try {
          return StegoPayloadResult.audio(decodeAudioBody(body));
        } on FormatException {
          return StegoPayloadResult.unsupported(type, body);
        }
      case StegoPayloadType.image:
        if (!looksLikeImageFile(body)) {
          return StegoPayloadResult.unsupported(type, body);
        }
        return StegoPayloadResult.image(body);
      case StegoPayloadType.other:
        return StegoPayloadResult.unsupported(type, body);
    }
  }

  /// Convert cover/payload WAV (typically PCM16) to 8 kHz mono u8 body.
  ///
  /// Peak-normalizes (after DC removal) so quiet speech uses the full u8 range;
  /// stores [peakAbs] so decode restores audible amplitude.
  static Uint8List encodeAudioBody(WavFile wav) {
    final mono = wav.toMono();
    final Int16List pcm16;
    if (mono.sampleRate == PayloadAudioDefaults.sampleRate) {
      pcm16 = mono.samples;
    } else {
      pcm16 = _resampleMono16(
        mono.samples,
        mono.sampleRate,
        PayloadAudioDefaults.sampleRate,
      );
    }
    final scaled = _pcm16ToUnsigned8PeakNormalized(pcm16);
    final out = Uint8List(audioMetaByteLength + scaled.u8.length);
    final bd = ByteData.sublistView(out);
    bd.setUint16(0, PayloadAudioDefaults.sampleRate, Endian.big);
    out[2] = PayloadAudioDefaults.channels;
    out[3] = PayloadAudioDefaults.bitsPerSample;
    bd.setUint32(4, scaled.u8.length, Endian.big);
    bd.setUint16(8, scaled.peakAbs, Endian.big);
    out.setRange(audioMetaByteLength, out.length, scaled.u8);
    return out;
  }

  static WavFile decodeAudioBody(Uint8List body) {
    if (body.length < audioMetaByteLengthLegacy) {
      throw const FormatException('Audio body too short');
    }
    final bd = ByteData.sublistView(body);
    final sampleRate = bd.getUint16(0, Endian.big);
    final channels = body[2];
    final bitsPerSample = body[3];
    final numSamples = bd.getUint32(4, Endian.big);
    if (channels != 1 || bitsPerSample != 8) {
      throw FormatException(
        'Unsupported audio body: ch=$channels bits=$bitsPerSample',
      );
    }

    final Int16List pcm16;
    if (body.length == audioMetaByteLengthLegacy + numSamples) {
      // Legacy: no peakAbs — linear map [-32768,32767] ↔ [0,255].
      final u8 = body.sublist(
        audioMetaByteLengthLegacy,
        audioMetaByteLengthLegacy + numSamples,
      );
      pcm16 = _unsigned8ToPcm16Linear(u8);
    } else if (body.length >= audioMetaByteLength + numSamples) {
      final peakAbs = bd.getUint16(8, Endian.big);
      final u8 = body.sublist(
        audioMetaByteLength,
        audioMetaByteLength + numSamples,
      );
      pcm16 = _unsigned8ToPcm16Scaled(u8, peakAbs == 0 ? 1 : peakAbs);
    } else {
      throw const FormatException('Audio body truncated');
    }

    return WavFile(
      sampleRate: sampleRate,
      numChannels: 1,
      bitsPerSample: 16,
      samples: pcm16,
    );
  }

  /// Upsample recovered 8 kHz payload for play/save player compatibility.
  static WavFile prepareAudioForExport(WavFile wav) {
    final mono = wav.toMono();
    if (mono.sampleRate == PayloadAudioDefaults.exportSampleRate) {
      return WavFile(
        sampleRate: mono.sampleRate,
        numChannels: 1,
        bitsPerSample: 16,
        samples: Int16List.fromList(mono.samples),
      );
    }
    final pcm = _resampleMono16(
      mono.samples,
      mono.sampleRate,
      PayloadAudioDefaults.exportSampleRate,
    );
    return WavFile(
      sampleRate: PayloadAudioDefaults.exportSampleRate,
      numChannels: 1,
      bitsPerSample: 16,
      samples: pcm,
    );
  }

  /// Bit length of an ASTG text envelope (unpadded).
  static int bitLengthForText(String text) {
    final body = utf8.encode(text);
    return (headerByteLength + body.length) * 8;
  }

  /// Bit length of an ASTG audio envelope for [wav] after 8 kHz u8 encode (unpadded).
  static int bitLengthForAudio(WavFile wav) {
    final body = encodeAudioBody(wav);
    return (headerByteLength + body.length) * 8;
  }

  /// Bit length of an ASTG image envelope for raw image file bytes (unpadded).
  static int bitLengthForImage(Uint8List imageFileBytes) =>
      (headerByteLength + imageFileBytes.length) * 8;

  static Int16List _resampleMono16(Int16List input, int fromRate, int toRate) {
    if (fromRate == toRate || input.isEmpty) {
      return Int16List.fromList(input);
    }
    final outLen = (input.length * toRate / fromRate).round().clamp(1, 1 << 30);
    final out = Int16List(outLen);
    for (var i = 0; i < outLen; i++) {
      final src = i * fromRate / toRate;
      final i0 = src.floor().clamp(0, input.length - 1);
      final i1 = (i0 + 1).clamp(0, input.length - 1);
      final t = src - i0;
      final v = input[i0] * (1.0 - t) + input[i1] * t;
      out[i] = v.round().clamp(-32768, 32767);
    }
    return out;
  }

  static ({Uint8List u8, int peakAbs}) _pcm16ToUnsigned8PeakNormalized(
    Int16List pcm16,
  ) {
    if (pcm16.isEmpty) {
      return (u8: Uint8List(0), peakAbs: 1);
    }
    var sum = 0.0;
    for (final s in pcm16) {
      sum += s;
    }
    final mean = sum / pcm16.length;
    var peak = 1.0;
    final centered = Float64List(pcm16.length);
    for (var i = 0; i < pcm16.length; i++) {
      final c = pcm16[i] - mean;
      centered[i] = c;
      final a = c.abs();
      if (a > peak) peak = a;
    }
    final peakAbs = peak.round().clamp(1, 32767);
    final out = Uint8List(pcm16.length);
    final scale = 127.0 / peakAbs;
    for (var i = 0; i < pcm16.length; i++) {
      out[i] = (centered[i] * scale + 128.0).round().clamp(0, 255);
    }
    return (u8: out, peakAbs: peakAbs);
  }

  static Int16List _unsigned8ToPcm16Scaled(Uint8List u8, int peakAbs) {
    final out = Int16List(u8.length);
    final scale = peakAbs / 127.0;
    for (var i = 0; i < u8.length; i++) {
      out[i] = ((u8[i] - 128) * scale).round().clamp(-32768, 32767);
    }
    return out;
  }

  static Int16List _unsigned8ToPcm16Linear(Uint8List u8) {
    final out = Int16List(u8.length);
    for (var i = 0; i < u8.length; i++) {
      out[i] = ((u8[i] << 8) - 32768).clamp(-32768, 32767);
    }
    return out;
  }
}
