import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../audio/wav_io.dart';
import 'stego_engine.dart';

/// Top-level helper params used by [StegoRunner.embed]. Must be top-level so
/// that they can cross the isolate boundary.
class _EmbedRequest {
  final StegoMode mode;
  final String text;
  final double r;
  final double x0;
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;
  final Int16List samples;

  const _EmbedRequest({
    required this.mode,
    required this.text,
    required this.r,
    required this.x0,
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
    required this.samples,
  });
}

/// Rich result of an isolate embed call; fields are all isolate-friendly
/// (primitives + Int16List) so they cross the message boundary safely.
class EmbedRunResult {
  final WavFile stego;
  final StegoMode mode;
  final int bitsEmbedded;
  final int capacityBits;
  final double? snrDb;
  final double? psnrDb;

  const EmbedRunResult({
    required this.stego,
    required this.mode,
    required this.bitsEmbedded,
    required this.capacityBits,
    this.snrDb,
    this.psnrDb,
  });

  /// Convenience: ratio of used vs. total embedding capacity (0..1).
  double get utilization =>
      capacityBits == 0 ? 0.0 : (bitsEmbedded / capacityBits).clamp(0.0, 1.0);
}

class _EmbedResponse {
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;
  final Int16List samples;
  final int modeIndex;
  final int bitsEmbedded;
  final int capacityBits;
  final double? snrDb;
  final double? psnrDb;

  const _EmbedResponse({
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
    required this.samples,
    required this.modeIndex,
    required this.bitsEmbedded,
    required this.capacityBits,
    this.snrDb,
    this.psnrDb,
  });

  EmbedRunResult toResult() => EmbedRunResult(
    stego: WavFile(
      sampleRate: sampleRate,
      numChannels: numChannels,
      bitsPerSample: bitsPerSample,
      samples: samples,
    ),
    mode: StegoMode.values[modeIndex],
    bitsEmbedded: bitsEmbedded,
    capacityBits: capacityBits,
    snrDb: snrDb,
    psnrDb: psnrDb,
  );
}

class _ExtractRequest {
  final double r;
  final double x0;
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;
  final Int16List samples;
  final StegoMode? mode;

  const _ExtractRequest({
    required this.r,
    required this.x0,
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
    required this.samples,
    required this.mode,
  });
}

/// Runs steganography work on a background isolate via [compute] so the UI
/// thread stays responsive even on long audio clips.
class StegoRunner {
  const StegoRunner._();

  /// Embeds [text] into [cover] (or synthesizes a carrier in FSK mode if
  /// cover is null). Returns a rich [EmbedRunResult] that contains the stego
  /// audio plus quality metrics — suitable for displaying SNR/PSNR/BER UI.
  static Future<EmbedRunResult> embed({
    required StegoMode mode,
    required String text,
    WavFile? cover,
    double r = 3.99,
    double x0 = 0.45,
  }) async {
    final coverWav =
        cover ??
        WavFile(
          sampleRate: 44100,
          numChannels: 1,
          bitsPerSample: 16,
          samples: Int16List(0),
        );
    final req = _EmbedRequest(
      mode: mode,
      text: text,
      r: r,
      x0: x0,
      sampleRate: coverWav.sampleRate,
      numChannels: coverWav.numChannels,
      bitsPerSample: coverWav.bitsPerSample,
      samples: coverWav.samples,
    );
    final res = await compute(_embedOnIsolate, req);
    return res.toResult();
  }

  static Future<String?> extract(
    WavFile stego, {
    StegoMode? mode,
    double r = 3.99,
    double x0 = 0.45,
  }) async {
    final req = _ExtractRequest(
      r: r,
      x0: x0,
      sampleRate: stego.sampleRate,
      numChannels: stego.numChannels,
      bitsPerSample: stego.bitsPerSample,
      samples: stego.samples,
      mode: mode,
    );
    return compute(_extractOnIsolate, req);
  }
}

_EmbedResponse _embedOnIsolate(_EmbedRequest req) {
  final engine = StegoEngine(r: req.r, x0: req.x0);
  final hasCover = req.samples.isNotEmpty;
  final cover = hasCover
      ? WavFile(
          sampleRate: req.sampleRate,
          numChannels: req.numChannels,
          bitsPerSample: req.bitsPerSample,
          samples: req.samples,
        )
      : null;
  final outcome = engine.embed(mode: req.mode, text: req.text, cover: cover);
  return _EmbedResponse(
    sampleRate: outcome.stego.sampleRate,
    numChannels: outcome.stego.numChannels,
    bitsPerSample: outcome.stego.bitsPerSample,
    samples: outcome.stego.samples,
    modeIndex: outcome.mode.index,
    bitsEmbedded: outcome.bitsEmbedded,
    capacityBits: outcome.capacityBits,
    snrDb: outcome.metrics?.snrDb,
    psnrDb: outcome.metrics?.psnrDb,
  );
}

String? _extractOnIsolate(_ExtractRequest req) {
  final engine = StegoEngine(r: req.r, x0: req.x0);
  final stego = WavFile(
    sampleRate: req.sampleRate,
    numChannels: req.numChannels,
    bitsPerSample: req.bitsPerSample,
    samples: req.samples,
  );
  return engine.extract(stego, mode: req.mode);
}
