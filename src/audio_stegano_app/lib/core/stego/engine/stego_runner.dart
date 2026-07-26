import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../audio/wav_io.dart';
import '../embed_message.dart';
import '../extract_message.dart';
import '../payload_envelope.dart';
import '../trained_autoencoder_loader.dart';

class _EmbedRequest {
  final String? text;
  final Uint8List? binaryMsg;
  final double r;
  final double x0;
  final int? fixedMsgBitLength;
  final String autoencoderJson;
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;
  final Int16List samples;

  const _EmbedRequest({
    this.text,
    this.binaryMsg,
    required this.r,
    required this.x0,
    this.fixedMsgBitLength,
    required this.autoencoderJson,
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
  final String autoencoderJson;
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;
  final Int16List samples;
  final int msgBitLength;

  const _ExtractRequest({
    required this.r,
    required this.x0,
    required this.autoencoderJson,
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
    required this.samples,
    required this.msgBitLength,
  });
}

/// Transferable extract result across isolates.
class ExtractPayloadRunResult {
  final int? typeCode;
  final bool isLegacy;
  final String? text;
  final int? audioSampleRate;
  final Int16List? audioSamples;
  final bool unsupported;

  const ExtractPayloadRunResult({
    this.typeCode,
    required this.isLegacy,
    this.text,
    this.audioSampleRate,
    this.audioSamples,
    this.unsupported = false,
  });

  StegoPayloadResult toPayloadResult() {
    if (unsupported) {
      final type = typeCode == null
          ? null
          : StegoPayloadType.tryParse(typeCode!);
      return StegoPayloadResult(
        type: type,
        isLegacy: false,
        rawBody: Uint8List(0),
      );
    }
    if (audioSamples != null && audioSampleRate != null) {
      return StegoPayloadResult.audio(
        WavFile(
          sampleRate: audioSampleRate!,
          numChannels: 1,
          bitsPerSample: 16,
          samples: audioSamples!,
        ),
      );
    }
    if (isLegacy) {
      return StegoPayloadResult.legacyText(text);
    }
    if (text != null) {
      return StegoPayloadResult.text(text!);
    }
    return StegoPayloadResult.legacyText(null);
  }
}

EmbedMessage _embedMessageFromRequest({
  required double r,
  required double x0,
  required String autoencoderJson,
}) {
  final ae = TrainedAutoencoderLoader.fromJsonString(autoencoderJson);
  return EmbedMessage(r: r, x0: x0, autoencoder: ae);
}

ExtractMessage _extractMessageFromRequest({
  required double r,
  required double x0,
  required String autoencoderJson,
}) {
  final ae = TrainedAutoencoderLoader.fromJsonString(autoencoderJson);
  return ExtractMessage(r: r, x0: x0, autoencoder: ae);
}

/// اجرای isolate روی [EmbedMessage] / [ExtractMessage]
class StegoRunner {
  const StegoRunner._();

  static Future<EmbedRunResult> embed({
    required String text,
    required WavFile cover,
    double r = 3.99,
    double x0 = 0.45,
    int? fixedMsgBitLength,
  }) async {
    final aeJson = await TrainedAutoencoderLoader.loadJsonString();
    final req = _EmbedRequest(
      text: text,
      r: r,
      x0: x0,
      fixedMsgBitLength: fixedMsgBitLength,
      autoencoderJson: aeJson,
      sampleRate: cover.sampleRate,
      numChannels: cover.numChannels,
      bitsPerSample: cover.bitsPerSample,
      samples: cover.samples,
    );
    final res = await compute(_embedOnIsolate, req);
    return res.toResult();
  }

  static Future<EmbedRunResult> embedBits({
    required Uint8List binaryMsg,
    required WavFile cover,
    double r = 3.99,
    double x0 = 0.45,
  }) async {
    final aeJson = await TrainedAutoencoderLoader.loadJsonString();
    final req = _EmbedRequest(
      binaryMsg: binaryMsg,
      r: r,
      x0: x0,
      autoencoderJson: aeJson,
      sampleRate: cover.sampleRate,
      numChannels: cover.numChannels,
      bitsPerSample: cover.bitsPerSample,
      samples: cover.samples,
    );
    final res = await compute(_embedOnIsolate, req);
    return res.toResult();
  }

  static Future<EmbedRunResult> embedAudio({
    required WavFile payloadAudio,
    required WavFile cover,
    double r = 3.99,
    double x0 = 0.45,
    int? fixedMsgBitLength,
  }) {
    final bits = PayloadEnvelope.packAudioBits(
      payloadAudio,
      fixedBitLength: fixedMsgBitLength,
    );
    return embedBits(binaryMsg: bits, cover: cover, r: r, x0: x0);
  }

  static Future<String?> extract(
    WavFile stego, {
    required int msgBitLength,
    double r = 3.99,
    double x0 = 0.45,
  }) async {
    final payload = await extractPayload(
      stego,
      msgBitLength: msgBitLength,
      r: r,
      x0: x0,
    );
    return payload?.text;
  }

  static Future<StegoPayloadResult?> extractPayload(
    WavFile stego, {
    required int msgBitLength,
    double r = 3.99,
    double x0 = 0.45,
  }) async {
    final aeJson = await TrainedAutoencoderLoader.loadJsonString();
    final req = _ExtractRequest(
      r: r,
      x0: x0,
      autoencoderJson: aeJson,
      sampleRate: stego.sampleRate,
      numChannels: stego.numChannels,
      bitsPerSample: stego.bitsPerSample,
      samples: stego.samples,
      msgBitLength: msgBitLength,
    );
    final res = await compute(_extractPayloadOnIsolate, req);
    return res?.toPayloadResult();
  }
}

_EmbedResponse _embedOnIsolate(_EmbedRequest req) {
  final embed = _embedMessageFromRequest(
    r: req.r,
    x0: req.x0,
    autoencoderJson: req.autoencoderJson,
  );
  final cover = WavFile(
    sampleRate: req.sampleRate,
    numChannels: req.numChannels,
    bitsPerSample: req.bitsPerSample,
    samples: req.samples,
  );
  final outcome = req.binaryMsg != null
      ? embed.runWithMetricsBits(cover: cover, binaryMsg: req.binaryMsg!)
      : embed.runWithMetrics(
          text: req.text ?? '',
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

ExtractPayloadRunResult? _extractPayloadOnIsolate(_ExtractRequest req) {
  final extract = _extractMessageFromRequest(
    r: req.r,
    x0: req.x0,
    autoencoderJson: req.autoencoderJson,
  );
  final stego = WavFile(
    sampleRate: req.sampleRate,
    numChannels: req.numChannels,
    bitsPerSample: req.bitsPerSample,
    samples: req.samples,
  );
  final payload = extract.runPayload(
    stego: stego,
    msgBitLength: req.msgBitLength,
  );
  if (payload == null) return null;
  if (payload.audio != null) {
    return ExtractPayloadRunResult(
      typeCode: StegoPayloadType.audio.code,
      isLegacy: false,
      audioSampleRate: payload.audio!.sampleRate,
      audioSamples: payload.audio!.samples,
    );
  }
  if (payload.rawBody != null && payload.text == null) {
    return ExtractPayloadRunResult(
      typeCode: payload.type?.code,
      isLegacy: false,
      unsupported: true,
    );
  }
  return ExtractPayloadRunResult(
    typeCode: payload.type?.code,
    isLegacy: payload.isLegacy,
    text: payload.text,
  );
}
