import 'package:audio_stegano_app/core/stego/cover_record_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requiredSamples adds safety margin', () {
    expect(
      CoverRecordBudget.requiredSamples(262144),
      262144 + CoverRecordBudget.safetySampleMargin,
    );
  });

  test('samplesSatisfied gates on buffered frames not wall-clock', () {
    const bits = 262144;
    final need = CoverRecordBudget.requiredSamples(bits);
    expect(CoverRecordBudget.samplesSatisfied(need - 1, bits), isFalse);
    expect(CoverRecordBudget.samplesSatisfied(need, bits), isTrue);
    expect(CoverRecordBudget.progressFromSamples(need ~/ 2, bits), closeTo(0.5, 0.01));
  });

  test('remainingFromSamples estimates time from missing capacity', () {
    final rem = CoverRecordBudget.remainingFromSamples(
      bufferedSamples: 0,
      requiredBits: 44100,
      sampleRate: 44100,
    );
    expect(rem.inMilliseconds, greaterThan(1000));
  });
}
