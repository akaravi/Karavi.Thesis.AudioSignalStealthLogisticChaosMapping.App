import 'dart:typed_data';

import 'package:audio_stegano_app/core/audio/wav_io.dart';
import 'package:audio_stegano_app/core/stego/payload_envelope.dart';
import 'package:audio_stegano_app/core/stego/stego_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayloadEnvelope', () {
    test('pack/unpack text round-trip', () {
      const msg = 'سلام hello';
      final bits = PayloadEnvelope.packTextBits(msg);
      expect(bits.length % 8, 0);
      expect(PayloadEnvelope.hasMagicBits(bits), isTrue);
      final result = PayloadEnvelope.unpackBits(bits);
      expect(result.isLegacy, isFalse);
      expect(result.type, StegoPayloadType.text);
      expect(result.text, msg);
    });

    test('fixed pad then unpack text', () {
      const msg = 'hi';
      final bits = PayloadEnvelope.packTextBits(msg, fixedBitLength: 2048);
      expect(bits.length, 2048);
      final result = PayloadEnvelope.unpackBits(bits);
      expect(result.text, msg);
    });

    test('legacy bits without magic decode as UTF-8 text', () {
      final legacy = MessageBits.fromUtf8Text('legacy');
      expect(PayloadEnvelope.hasMagicBits(legacy), isFalse);
      final result = PayloadEnvelope.unpackBits(legacy);
      expect(result.isLegacy, isTrue);
      expect(result.text, 'legacy');
    });

    test('audio body encode/decode round-trip sample count', () {
      final pcm = Int16List(800); // 0.1s @ 8kHz
      for (var i = 0; i < pcm.length; i++) {
        pcm[i] = (i % 256) * 100;
      }
      final wav = WavFile(
        sampleRate: 8000,
        numChannels: 1,
        bitsPerSample: 16,
        samples: pcm,
      );
      final bits = PayloadEnvelope.packAudioBits(wav);
      final result = PayloadEnvelope.unpackBits(bits);
      expect(result.type, StegoPayloadType.audio);
      expect(result.audio, isNotNull);
      expect(result.audio!.sampleRate, 8000);
      expect(result.audio!.samples.length, 800);
    });

    test('image JPEG pack/unpack round-trip', () {
      final jpeg = Uint8List(68);
      jpeg[0] = 0xFF;
      jpeg[1] = 0xD8;
      jpeg[2] = 0xFF;
      jpeg[3] = 0xD9;
      final bits = PayloadEnvelope.packImageBits(jpeg);
      expect(PayloadEnvelope.hasMagicBits(bits), isTrue);
      final result = PayloadEnvelope.unpackBits(bits);
      expect(result.type, StegoPayloadType.image);
      expect(result.imageBytes, isNotNull);
      expect(result.imageBytes, jpeg);
    });

    test('image bit budget helper leaves room under fixed bits', () {
      final maxBytes =
          PayloadImageDefaults.maxImageBytesForBitBudget(262144);
      expect(maxBytes, greaterThan(1000));
      expect(
        PayloadEnvelope.bitLengthForImage(Uint8List(maxBytes)),
        lessThanOrEqualTo(262144),
      );
    });

    test('quiet speech peak-normalize keeps audible energy', () {
      final pcm = Int16List(1600);
      for (var i = 0; i < pcm.length; i++) {
        // ~±400 peak — collapses to silence under old >>8 map
        pcm[i] = ((i % 40) < 20 ? 400 : -400);
      }
      final wav = WavFile(
        sampleRate: 8000,
        numChannels: 1,
        bitsPerSample: 16,
        samples: pcm,
      );
      final recovered = PayloadEnvelope.decodeAudioBody(
        PayloadEnvelope.encodeAudioBody(wav),
      );
      var peak = 0;
      for (final s in recovered.samples) {
        final a = s.abs();
        if (a > peak) peak = a;
      }
      expect(peak, greaterThan(200));
    });

    test('prepareAudioForExport upsamples to 16 kHz', () {
      final pcm = Int16List(800);
      for (var i = 0; i < pcm.length; i++) {
        pcm[i] = (i % 50) * 200;
      }
      final wav = WavFile(
        sampleRate: 8000,
        numChannels: 1,
        bitsPerSample: 16,
        samples: pcm,
      );
      final exported = PayloadEnvelope.prepareAudioForExport(wav);
      expect(exported.sampleRate, PayloadAudioDefaults.exportSampleRate);
      expect(exported.samples.length, greaterThan(pcm.length));
    });

    test('bit budget fits ~4s of 8kHz u8 under 262144 bits', () {
      final maxSamples =
          PayloadAudioDefaults.maxPcmSamplesForBitBudget(262144);
      expect(maxSamples, greaterThan(30000));
      final dur = PayloadAudioDefaults.maxDurationForBitBudget(262144);
      expect(dur.inMilliseconds, greaterThan(3500));
    });

    test('oversized envelope throws on fixed limit', () {
      final huge = 'x' * 400;
      expect(
        () => PayloadEnvelope.packTextBits(huge, fixedBitLength: 64),
        throwsArgumentError,
      );
    });
  });
}
