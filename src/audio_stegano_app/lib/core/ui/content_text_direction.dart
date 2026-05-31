import 'package:flutter/material.dart';

/// Resolves text direction for input/display based on content vs UI locale.
abstract final class ContentTextDirection {
  static final RegExp _rtlScript = RegExp(
    r'[\u0590-\u05FF\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  /// Latin letters (incl. extended), digits, whitespace, common Western punctuation.
  static final RegExp _latinOnly = RegExp(
    r'''^[\s0-9A-Za-z\u00C0-\u024F\u1E00-\u1EFF.,:;!?@#$%^&*()_+\-=\[\]{}|\\/<>\"'`~]*$''',
  );

  static bool containsRtlScript(String text) => _rtlScript.hasMatch(text);

  static bool isLatinOnly(String text) {
    if (text.trim().isEmpty) return false;
    if (containsRtlScript(text)) return false;
    return _latinOnly.hasMatch(text);
  }

  static TextDirection resolve(
    String text, {
    required TextDirection localeDirection,
    bool forceLatinLtr = false,
  }) {
    if (forceLatinLtr) return TextDirection.ltr;
    if (text.trim().isEmpty) return localeDirection;
    if (containsRtlScript(text)) return TextDirection.rtl;
    if (isLatinOnly(text)) return TextDirection.ltr;
    return localeDirection;
  }
}
