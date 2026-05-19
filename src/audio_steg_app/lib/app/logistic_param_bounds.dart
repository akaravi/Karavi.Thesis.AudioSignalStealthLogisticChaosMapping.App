/// UI and algorithm bounds for logistic map parameters (MATLAB port).
class LogisticParamBounds {
  LogisticParamBounds._();

  /// Slider / manual entry range for [r] (chaotic regime subset).
  static const double rMin = 3.5;
  static const double rMax = 4.0;

  /// Slider / manual entry range for [x0] (open interval (0,1)).
  static const double x0Min = 0.01;
  static const double x0Max = 0.99;

  static double clampR(double value) => value.clamp(rMin, rMax);
  static double clampX0(double value) => value.clamp(x0Min, x0Max);

  static double? tryParseR(String text) {
    final v = _tryParse(text);
    if (v == null || v <= 0 || v > 4.0) return null;
    return clampR(v);
  }

  static double? tryParseX0(String text) {
    final v = _tryParse(text);
    if (v == null || v <= 0 || v >= 1) return null;
    return clampX0(v);
  }

  static double? _tryParse(String text) {
    final t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }
}
