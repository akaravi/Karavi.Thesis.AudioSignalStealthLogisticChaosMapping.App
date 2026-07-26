import 'package:audio_stegano_app/core/stego/capacity_exceeded_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tryParse extracts needed and available bits', () {
    final parsed = CapacityExceededException.tryParse(
      'Message too long: needs 400000 bits, capacity 144176',
    );
    expect(parsed, isNotNull);
    expect(parsed!.neededBits, 400000);
    expect(parsed.availableBits, 144176);
  });

  test('toString stays machine-parseable', () {
    const ex = CapacityExceededException(
      neededBits: 10,
      availableBits: 5,
    );
    expect(
      CapacityExceededException.tryParse(ex.toString())?.neededBits,
      10,
    );
  });
}
