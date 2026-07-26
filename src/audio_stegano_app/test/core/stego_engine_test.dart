import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_stegano_app/core/audio/wav_io.dart';
import 'package:audio_stegano_app/core/stego/stego.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

WavFile _sineCover({int seconds = 4}) {
  const fs = 44100;
  final n = seconds * fs;
  final s = Int16List(n);
  for (var i = 0; i < n; i++) {
    s[i] = (math.sin(2 * math.pi * 440 * i / fs) * 32700).round().clamp(
      -32768,
      32767,
    );
  }
  return WavFile(sampleRate: fs, numChannels: 1, bitsPerSample: 16, samples: s);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MessageBlockAutoencoder autoencoder;

  setUpAll(() async {
    final json = await rootBundle.loadString(
      TrainedAutoencoderLoader.assetPath,
    );
    autoencoder = MessageBlockAutoencoder.fromJsonString(json);
  });

  group('StegoEngine — trained autoencoder (ae_xor only)', () {
    test('loads weights and runs embed/extract pipeline', () async {
      final wm = AudioWatermarking(autoencoder: autoencoder);
      final cover = _sineCover();
      const msg = 'Test';
      final out = wm.embed(text: msg, cover: cover);
      expect(out.bitsEmbedded, PayloadEnvelope.packTextBits(msg).length);
      final extracted = wm.extract(
        stego: out.stego,
        msgBitLength: out.bitsEmbedded,
      );
      expect(extracted, msg);
      final typed = wm.extractPayload(
        stego: out.stego,
        msgBitLength: out.bitsEmbedded,
      );
      expect(typed?.isLegacy, isFalse);
      expect(typed?.type, StegoPayloadType.text);
      expect(typed?.text, msg);
    });

    test('embed/extract audio payload round-trip', () {
      final wm = AudioWatermarking(autoencoder: autoencoder);
      final cover = _sineCover(seconds: 6);
      final pcm = Int16List(400);
      for (var i = 0; i < pcm.length; i++) {
        pcm[i] = (i % 256) * 100;
      }
      final payload = WavFile(
        sampleRate: PayloadAudioDefaults.sampleRate,
        numChannels: 1,
        bitsPerSample: 16,
        samples: pcm,
      );
      final out = wm.embedAudio(cover: cover, payloadAudio: payload);
      final typed = wm.extractPayload(
        stego: out.stego,
        msgBitLength: out.bitsEmbedded,
      );
      expect(typed?.type, StegoPayloadType.audio);
      expect(typed?.audio?.sampleRate, PayloadAudioDefaults.sampleRate);
      expect(typed?.audio?.samples.length, 400);
    });
  });

  group('StegoEngine — main_steganography.m flow', () {
    test('embed and extract round-trip with msg_len', () {
      final eng = StegoEngine(autoencoder: autoencoder);
      final cover = _sineCover();
      const msg = 'پیام کامل برای حالت دیجیتال.';
      final out = eng.embed(text: msg, cover: cover);
      final extracted = eng.extract(out.stego, out.bitsEmbedded);
      expect(extracted, msg);
    });

    test('reports evaluate_stego metrics', () {
      final eng = StegoEngine(autoencoder: autoencoder);
      final cover = _sineCover();
      const msg = 'metrics';
      final out = eng.embed(text: msg, cover: cover);
      expect(out.bitsEmbedded, greaterThan(0));
      expect(out.capacityBits, greaterThan(out.bitsEmbedded));
      expect(out.metrics.berPercent, 0.0);
      expect(out.metrics.snrDb, greaterThan(40));
      expect(out.metrics.npcrPercent, greaterThan(0.0));
    });

    test('wrong key returns null or wrong text', () {
      final engEnc = StegoEngine(x0: 0.45, autoencoder: autoencoder);
      final engDec = StegoEngine(x0: 0.46, autoencoder: autoencoder);
      final cover = _sineCover();
      final out = engEnc.embed(text: 'Secret', cover: cover);
      final extracted = engDec.extract(out.stego, out.bitsEmbedded);
      expect(extracted, isNot('Secret'));
    });
  });
}
