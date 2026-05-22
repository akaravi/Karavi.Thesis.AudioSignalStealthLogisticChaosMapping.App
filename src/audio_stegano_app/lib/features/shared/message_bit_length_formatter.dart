import 'package:flutter/services.dart';

import '../../core/stego/audio_watermarking.dart';

/// Limits UTF-8 message input to [maxBits] (LSB bit length).
class MessageBitLengthFormatter extends TextInputFormatter {
  const MessageBitLengthFormatter(this.maxBits);

  final int maxBits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (MessageBits.bitLengthForText(newValue.text) <= maxBits) {
      return newValue;
    }
    var text = newValue.text;
    while (text.isNotEmpty && MessageBits.bitLengthForText(text) > maxBits) {
      text = text.substring(0, text.length - 1);
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
