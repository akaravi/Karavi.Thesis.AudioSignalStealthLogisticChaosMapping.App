import 'dart:typed_data';

import '../../audio/wav_io.dart';
import '../codecs/fsk_codec.dart';
import '../codecs/lsb_codec.dart';
import '../metrics/metrics.dart';
import '../text/text_codec.dart';

/// Two stego strategies that the app exposes:
///   * [StegoMode.digital]   — exact MATLAB LSB+Chaos (file-only)
///   * [StegoMode.overTheAir] — robust BFSK+Chaos (speaker → microphone)
enum StegoMode { digital, overTheAir }

extension StegoModeX on StegoMode {
  String get id => switch (this) {
    StegoMode.digital => 'digital',
    StegoMode.overTheAir => 'overTheAir',
  };

  static StegoMode fromId(String id) => StegoMode.values.firstWhere(
    (m) => m.id == id,
    orElse: () => StegoMode.digital,
  );
}

/// Result of an embed operation produced by [StegoEngine.embed].
class EmbedOutcome {
  final WavFile stego;
  final StegoMode mode;
  final StegoMetrics? metrics;

  /// Total payload bits actually placed into the stego signal.
  final int bitsEmbedded;

  /// Theoretical maximum payload bits the cover could carry (mode-aware).
  final int capacityBits;

  const EmbedOutcome({
    required this.stego,
    required this.mode,
    required this.bitsEmbedded,
    required this.capacityBits,
    this.metrics,
  });
}

/// Strategy facade for steganography.
class StegoEngine {
  final double r;
  final double x0;

  const StegoEngine({this.r = 3.99, this.x0 = 0.45});

  LsbCodec get _lsb => LsbCodec(r: r, x0: x0);
  FskCodec get _fsk => FskCodec(r: r, x0: x0);

  /// Embeds [text] into a cover. For [StegoMode.overTheAir] the [cover] is
  /// optional — if omitted, a synthesized FSK-only signal is produced.
  EmbedOutcome embed({
    required StegoMode mode,
    required String text,
    WavFile? cover,
  }) {
    switch (mode) {
      case StegoMode.digital:
        if (cover == null) {
          throw ArgumentError('Digital LSB mode requires a cover audio.');
        }
        final embed = _lsb.embedText(cover, text);
        final coverMono = cover.toMono();
        final metrics = StegoMetrics.compute(
          cover: coverMono.samples,
          stego: embed.stego.samples,
          originalBits: Uint8List(0),
          extractedBits: Uint8List(0),
        );
        return EmbedOutcome(
          stego: embed.stego,
          mode: mode,
          metrics: metrics,
          bitsEmbedded: embed.bitsEmbedded,
          capacityBits: embed.capacityBits,
        );

      case StegoMode.overTheAir:
        final fskSignal = _fsk.modulate(text);
        var fskPcm = FskCodec.toPcm16(fskSignal);
        final stegoSamples = _mixFskWithCover(fskPcm, cover);
        StegoMetrics? metrics;
        if (cover != null) {
          // Pad/trim cover to stego length so SNR is well-defined.
          final coverPad = _padOrTrim(
            cover.toMono().samples,
            stegoSamples.length,
          );
          metrics = StegoMetrics.compute(
            cover: coverPad,
            stego: stegoSamples,
            originalBits: Uint8List(0),
            extractedBits: Uint8List(0),
          );
        }
        // Theoretical capacity for OTA: each FSK symbol carries 1 information
        // bit — but Hamming(7,4) means only 4/7 are payload, and we further
        // need TextCodec.headerBits + payload*8. Capacity therefore scales
        // with the duration of the cover (or the fsk signal itself when no
        // cover). We approximate it by the actual modulated bits length so the
        // UI can show a meaningful "X bits / Y bits" ratio.
        final embeddedBits = TextCodec.requiredBits(text);
        return EmbedOutcome(
          stego: WavFile(
            sampleRate: FskCodec.sampleRate,
            numChannels: 1,
            bitsPerSample: 16,
            samples: stegoSamples,
          ),
          mode: mode,
          metrics: metrics,
          bitsEmbedded: embeddedBits,
          capacityBits: embeddedBits,
        );
    }
  }

  Int16List _mixFskWithCover(Int16List fskPcm, WavFile? cover) {
    if (cover == null) return fskPcm;
    final coverMono = cover.toMono();
    final n = fskPcm.length;
    final out = Int16List(n);
    for (var i = 0; i < n; i++) {
      final c = i < coverMono.samples.length ? coverMono.samples[i] : 0;
      var v = (c ~/ 4) + (fskPcm[i] ~/ 2);
      if (v > 32767) v = 32767;
      if (v < -32768) v = -32768;
      out[i] = v;
    }
    return out;
  }

  Int16List _padOrTrim(Int16List src, int targetLength) {
    if (src.length == targetLength) return src;
    final out = Int16List(targetLength);
    final n = src.length < targetLength ? src.length : targetLength;
    for (var i = 0; i < n; i++) {
      out[i] = src[i];
    }
    return out;
  }

  /// Extracts text from a stego WAV, trying the explicit [mode] first.
  /// If [mode] is null the engine will try over-the-air FSK then digital LSB.
  String? extract(WavFile stego, {StegoMode? mode}) {
    final modes = mode != null
        ? [mode]
        : [StegoMode.overTheAir, StegoMode.digital];
    for (final m in modes) {
      final text = _tryExtract(stego, m);
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  String? _tryExtract(WavFile stego, StegoMode mode) {
    switch (mode) {
      case StegoMode.digital:
        final r = _lsb.extractText(stego);
        return r.text;
      case StegoMode.overTheAir:
        final mono = stego.toMono();
        final f = FskCodec.fromPcm16(mono.samples);
        return _fsk.demodulate(f);
    }
  }
}
