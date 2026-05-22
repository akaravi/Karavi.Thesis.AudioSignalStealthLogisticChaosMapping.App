import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../audio/wav_io.dart';
import '../audio_watermarking.dart';

class _EmbedRequest {
  final String text;
  final double r;
  final double x0;
  final int? fixedMsgBitLength;
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;
  final Int16List samples;

  const _EmbedRequest({
    required this.text,
    required this.r,
    required this.x0,
    this.fixedMsgBitLength,
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
    required this.samples,
  });
}

class EmbedRunResult {
  final WavFile stego;
  final int bitsEmbedded;
  final int capacityBits;
  final int msgBitLength;
  final double? snrDb;
  final double? psnrDb;
  final double? berPercent;
  final double? npcrPercent;
  final double? uaciPercent;

  const EmbedRunResult({
    required this.stego,
    required this.bitsEmbedded,
    required this.capacityBits,
    required this.msgBitLength,
    this.snrDb,
    this.psnrDb,
    this.berPercent,
    this.npcrPercent,
    this.uaciPercent,
  });

  double get utilization =>
      capacityBits == 0 ? 0.0 : (bitsEmbedded / capacityBits).clamp(0.0, 1.0);
}

class _EmbedResponse {
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;
  final Int16List samples;
  final int bitsEmbedded;
  final int capacityBits;
  final int msgBitLength;
  final double? snrDb;
  final double? psnrDb;
  final double? berPercent;
  final double? npcrPercent;
  final double? uaciPercent;

  const _EmbedResponse({
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
    required this.samples,
    required this.bitsEmbedded,
    required this.capacityBits,
    required this.msgBitLength,
    this.snrDb,
    this.psnrDb,
    this.berPercent,
    this.npcrPercent,
    this.uaciPercent,
  });

  EmbedRunResult toResult() => EmbedRunResult(
    stego: WavFile(
      sampleRate: sampleRate,
      numChannels: numChannels,
      bitsPerSample: bitsPerSample,
      samples: samples,
    ),
    bitsEmbedded: bitsEmbedded,
    capacityBits: capacityBits,
    msgBitLength: msgBitLength,
    snrDb: snrDb,
    psnrDb: psnrDb,
    berPercent: berPercent,
    npcrPercent: npcrPercent,
    uaciPercent: uaciPercent,
  );
}

class _ExtractRequest {
  final double r;
  final double x0;
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;
  final Int16List samples;
  final int msgBitLength;

  const _ExtractRequest({
    required this.r,
    required this.x0,
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
    required this.samples,
    required this.msgBitLength,
  });
}

class StegoRunner {
  const StegoRunner._();

  static Future<EmbedRunResult> embed({
    required String text,
    required WavFile cover,
    double r = 3.99,
    double x0 = 0.45,
    int? fixedMsgBitLength,
  }) async {
    final req = _EmbedRequest(
      text: text,
      r: r,
      x0: x0,
      fixedMsgBitLength: fixedMsgBitLength,
      sampleRate: cover.sampleRate,
      numChannels: cover.numChannels,
      bitsPerSample: cover.bitsPerSample,
      samples: cover.samples,
    );
    final res = await compute(_embedOnIsolate, req);
    return res.toResult();
  }

  static Future<String?> extract(
    WavFile stego, {
    required int msgBitLength,
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
      msgBitLength: msgBitLength,
    );
    return compute(_extractOnIsolate, req);
  }
}

_EmbedResponse _embedOnIsolate(_EmbedRequest req) {
  final wm = AudioWatermarking(r: req.r, x0: req.x0);
  final cover = WavFile(
    sampleRate: req.sampleRate,
    numChannels: req.numChannels,
    bitsPerSample: req.bitsPerSample,
    samples: req.samples,
  );
  final outcome = wm.embed(
    text: req.text,
    cover: cover,
    fixedMsgBitLength: req.fixedMsgBitLength,
  );
  final m = outcome.metrics;
  return _EmbedResponse(
    sampleRate: outcome.stego.sampleRate,
    numChannels: outcome.stego.numChannels,
    bitsPerSample: outcome.stego.bitsPerSample,
    samples: outcome.stego.samples,
    bitsEmbedded: outcome.bitsEmbedded,
    capacityBits: outcome.capacityBits,
    msgBitLength: outcome.bitsEmbedded,
    snrDb: m.snrDb,
    psnrDb: m.psnrDb,
    berPercent: m.berPercent,
    npcrPercent: m.npcrPercent,
    uaciPercent: m.uaciPercent,
  );
}

String? _extractOnIsolate(_ExtractRequest req) {
  final wm = AudioWatermarking(r: req.r, x0: req.x0);
  final stego = WavFile(
    sampleRate: req.sampleRate,
    numChannels: req.numChannels,
    bitsPerSample: req.bitsPerSample,
    samples: req.samples,
  );
  return wm.extract(stego: stego, msgBitLength: req.msgBitLength);
}
