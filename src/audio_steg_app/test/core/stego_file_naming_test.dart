import 'package:audio_steg_app/core/audio/stego_file_naming.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stegoWavFileName uses YYYY_MM_DD_HHMM_msg_len', () {
    final name = stegoWavFileName(
      824,
      DateTime(2026, 5, 18, 14, 30),
    );
    expect(name, 'stego_2026_05_18_1430_824.wav');
  });
}
