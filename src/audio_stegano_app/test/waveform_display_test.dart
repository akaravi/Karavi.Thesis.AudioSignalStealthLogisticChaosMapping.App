import 'package:audio_stegano_app/core/audio/waveform_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('waveformNormalizeForDisplay scales quiet peaks near target', () {
    final cover = List<double>.filled(8, 0.05);
    final stego = List<double>.filled(8, 0.04);
    final out = waveformNormalizeForDisplay([cover, stego], targetPeak: 0.92);
    expect(out[0].first, closeTo(0.92, 0.001));
    expect(out[1].first, closeTo(0.92 * 0.04 / 0.05, 0.001));
  });

  test('waveformEnvelopePeak returns joint max', () {
    expect(
      waveformEnvelopePeak([
        [0.1, 0.2],
        [0.15, 0.05],
      ]),
      0.2,
    );
  });
}
