import 'package:flutter/material.dart';

/// Semantic icon accents — meaning-driven hues (not rainbow decoration).
///
/// Light/dark pairs keep ≥3:1 vs typical surfaces for non-text UI (WCAG).
enum AppIconAccent {
  /// Embed / stego layers — brand violet.
  embed,

  /// Extract / search — teal.
  extract,

  /// Settings / gear — amber.
  settings,

  /// About / person — rose.
  about,

  /// Help — sky blue.
  help,

  /// New / create — emerald.
  create,

  /// Verify / success — green.
  verify,

  /// Share — azure.
  share,

  /// Save — deep violet (filled CTAs).
  save,

  /// Copy — indigo.
  copy,

  /// GitHub / code — slate.
  github,

  /// Thesis / school — violet.
  thesis,

  /// Web / globe — blue.
  web,

  /// Company / building — teal.
  company,

  /// Phone — green.
  phone,

  /// Email — coral.
  email,

  /// Audio file hero — brand soft-purple.
  audio,

  /// Folder / pick file — amber.
  folder,

  /// Unlock / decrypt — orange.
  unlock,

  /// Numbered list / bit length — indigo.
  list,

  /// Play transport — emerald.
  play,

  /// Pause — amber.
  pause,

  /// Stop — rose.
  stop,
}

/// Resolves [AppIconAccent] to theme-aware foreground / soft container colors.
abstract final class AppIconAccents {
  static Color foreground(AppIconAccent accent, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (accent) {
      case AppIconAccent.embed:
        return dark ? const Color(0xFFD4C2F0) : const Color(0xFF5B3F91);
      case AppIconAccent.extract:
        return dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
      case AppIconAccent.settings:
        return dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
      case AppIconAccent.about:
        return dark ? const Color(0xFFF9A8D4) : const Color(0xFFBE185D);
      case AppIconAccent.help:
        return dark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1);
      case AppIconAccent.create:
        return dark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
      case AppIconAccent.verify:
        return dark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
      case AppIconAccent.share:
        return dark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
      case AppIconAccent.save:
        return dark ? const Color(0xFFE9D5FF) : const Color(0xFF5B21B6);
      case AppIconAccent.copy:
        return dark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA);
      case AppIconAccent.github:
        return dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
      case AppIconAccent.thesis:
        return dark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9);
      case AppIconAccent.web:
        return dark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
      case AppIconAccent.company:
        return dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
      case AppIconAccent.phone:
        return dark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A);
      case AppIconAccent.email:
        return dark ? const Color(0xFFFDA4AF) : const Color(0xFFE11D48);
      case AppIconAccent.audio:
        return dark ? const Color(0xFFD4C2F0) : const Color(0xFF7A68A8);
      case AppIconAccent.folder:
        return dark ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
      case AppIconAccent.unlock:
        return dark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C);
      case AppIconAccent.list:
        return dark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
      case AppIconAccent.play:
        return dark ? const Color(0xFF6EE7B7) : const Color(0xFF059669);
      case AppIconAccent.pause:
        return dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case AppIconAccent.stop:
        return dark ? const Color(0xFFFDA4AF) : const Color(0xFFDC2626);
    }
  }

  /// Soft tint behind tonal / FAB surfaces.
  static Color container(AppIconAccent accent, Brightness brightness) {
    final fg = foreground(accent, brightness);
    final dark = brightness == Brightness.dark;
    return fg.withValues(alpha: dark ? 0.28 : 0.16);
  }

  /// Stronger fill for primary (filled) action buttons.
  static Color fill(AppIconAccent accent, Brightness brightness) {
    return foreground(accent, brightness);
  }

  static Color onFill(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF1A1524)
        : Colors.white;
  }
}
