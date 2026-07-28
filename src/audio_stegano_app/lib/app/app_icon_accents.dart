import 'package:flutter/material.dart';

/// Semantic icon accents — meaning-driven, **role-collapsed** (not rainbow).
///
/// ui-ux-pro-max: Soft UI Evolution + Inclusive Design —
/// few hues, WCAG-friendly pairs, icons+color (never color alone).
///
/// Light/dark pairs target ≥4.5:1 vs app surfaces for icon glyphs.
enum AppIconAccent {
  /// Embed / stego layers — brand.
  embed,

  /// Extract / decrypt — trust teal.
  extract,

  /// Settings / gear — warning amber.
  settings,

  /// About / person — brand (same family as embed; no pink nav).
  about,

  /// Help — info blue.
  help,

  /// New / create — success green.
  create,

  /// Verify / success — success green.
  verify,

  /// Share — info blue.
  share,

  /// Save — brand.
  save,

  /// Copy — neutral slate.
  copy,

  /// GitHub / code — neutral slate.
  github,

  /// Thesis / school — brand.
  thesis,

  /// Web / globe — info blue.
  web,

  /// Company / building — trust teal.
  company,

  /// Phone — success green.
  phone,

  /// Email — danger rose (action, not nav).
  email,

  /// Audio file hero — brand.
  audio,

  /// Folder / pick file — warning amber.
  folder,

  /// Unlock / decrypt CTA — trust teal.
  unlock,

  /// Numbered list / bit length — info blue.
  list,

  /// Play transport — success green.
  play,

  /// Pause — neutral (transport chrome, not a second warning).
  pause,

  /// Stop — danger.
  stop,
}

/// Shared Soft UI / security role hues (collapsed palette).
abstract final class _IconRoles {
  // Brand / security text blue
  static const brandLight = Color(0xFF0C4A6E);
  static const brandDark = Color(0xFF7DD3FC);

  // Trust teal (extract / unlock)
  static const trustLight = Color(0xFF0F766E);
  static const trustDark = Color(0xFF5EEAD4);

  // Warning amber (settings / folder)
  static const warnLight = Color(0xFFB45309);
  static const warnDark = Color(0xFFFBBF24);

  // Danger (stop / email)
  static const dangerLight = Color(0xFFB91C1C);
  static const dangerDark = Color(0xFFFCA5A5);

  // Success (create / verify / play)
  static const successLight = Color(0xFF15803D);
  static const successDark = Color(0xFF86EFAC);

  // Info (help / share / web)
  static const infoLight = Color(0xFF0369A1);
  static const infoDark = Color(0xFF38BDF8);

  // Neutral slate (copy / github / pause)
  static const neutralLight = Color(0xFF334155);
  static const neutralDark = Color(0xFFCBD5E1);
}

/// Resolves [AppIconAccent] to theme-aware foreground / soft container colors.
abstract final class AppIconAccents {
  static Color foreground(AppIconAccent accent, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (accent) {
      case AppIconAccent.embed:
      case AppIconAccent.about:
      case AppIconAccent.save:
      case AppIconAccent.thesis:
      case AppIconAccent.audio:
        return dark ? _IconRoles.brandDark : _IconRoles.brandLight;
      case AppIconAccent.extract:
      case AppIconAccent.company:
      case AppIconAccent.unlock:
        return dark ? _IconRoles.trustDark : _IconRoles.trustLight;
      case AppIconAccent.settings:
      case AppIconAccent.folder:
        return dark ? _IconRoles.warnDark : _IconRoles.warnLight;
      case AppIconAccent.help:
      case AppIconAccent.share:
      case AppIconAccent.web:
      case AppIconAccent.list:
        return dark ? _IconRoles.infoDark : _IconRoles.infoLight;
      case AppIconAccent.create:
      case AppIconAccent.verify:
      case AppIconAccent.play:
      case AppIconAccent.phone:
        return dark ? _IconRoles.successDark : _IconRoles.successLight;
      case AppIconAccent.stop:
      case AppIconAccent.email:
        return dark ? _IconRoles.dangerDark : _IconRoles.dangerLight;
      case AppIconAccent.copy:
      case AppIconAccent.github:
      case AppIconAccent.pause:
        return dark ? _IconRoles.neutralDark : _IconRoles.neutralLight;
    }
  }

  /// Soft tint behind tonal / FAB surfaces (Soft UI — readable, not neon).
  static Color container(AppIconAccent accent, Brightness brightness) {
    final fg = foreground(accent, brightness);
    final dark = brightness == Brightness.dark;
    return fg.withValues(alpha: dark ? 0.26 : 0.14);
  }

  /// Stronger fill for primary (filled) action buttons.
  static Color fill(AppIconAccent accent, Brightness brightness) {
    return foreground(accent, brightness);
  }

  static Color onFill(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF0B1220)
        : Colors.white;
  }
}
