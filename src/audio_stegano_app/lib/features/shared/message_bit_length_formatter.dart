import 'package:flutter/services.dart';

import '../../core/stego/payload_envelope.dart';

/// Limits UTF-8 message input so ASTG text envelope fits in [maxBits].
class MessageBitLengthFormatter extends TextInputFormatter {
  const MessageBitLengthFormatter(this.maxBits);

  final int maxBits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (PayloadEnvelope.bitLengthForText(newValue.text) <= maxBits) {
      return newValue;
    }
    var text = newValue.text;
    while (text.isNotEmpty &&
        PayloadEnvelope.bitLengthForText(text) > maxBits) {
      text = text.substring(0, text.length - 1);
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
