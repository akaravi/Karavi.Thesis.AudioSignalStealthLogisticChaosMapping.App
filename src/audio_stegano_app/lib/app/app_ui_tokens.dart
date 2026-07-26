import 'package:flutter/material.dart';

/// Shared visual tokens — one standard across Embed / Extract / Settings / About.
abstract final class AppUiTokens {
  static const double radiusCard = 20;
  static const double radiusInput = 16;
  static const double radiusChip = 12;
  static const double radiusImage = 12;
  static const double radiusFab = 22;

  static const EdgeInsets pagePadding = EdgeInsets.all(16);
  static const EdgeInsets pagePaddingTopToolbar = EdgeInsets.fromLTRB(
    16,
    8,
    16,
    16,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(10);

  static const double sectionGap = 16;
  static const double toolbarFabGap = 8;

  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusCard);
  static BorderRadius get inputBorderRadius =>
      BorderRadius.circular(radiusInput);
  static BorderRadius get imageBorderRadius =>
      BorderRadius.circular(radiusImage);

  static ShapeBorder get cardShape =>
      RoundedRectangleBorder(borderRadius: cardBorderRadius);

  /// Success / result panel outline (Embed + Extract parity).
  static BorderSide resultOutline(ColorScheme scheme) =>
      BorderSide(color: scheme.primary.withValues(alpha: 0.45));
}
