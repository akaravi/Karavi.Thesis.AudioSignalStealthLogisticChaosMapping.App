import 'package:flutter/material.dart';

/// Brand seed — ui-ux-pro-max Soft UI Evolution + security-utility palette.
///
/// Primary is professional security blue (not washed soft-purple).
/// Only light/dark brightness varies via [ColorScheme.fromSeed].
abstract final class AppBrandColors {
  /// Material 3 seed — security blue `#0369A1`.
  static const Color primary = Color(0xFF0369A1);

  /// Legacy alias kept so older call sites compile; prefer [primary].
  static const Color softPurple = primary;
}
