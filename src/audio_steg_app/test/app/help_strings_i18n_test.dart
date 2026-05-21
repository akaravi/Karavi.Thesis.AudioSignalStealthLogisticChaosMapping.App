import 'package:audio_steg_app/app/app_locale.dart';
import 'package:audio_steg_app/app/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards help popup strings: every key must be non-empty in fa, en, ar, fr.
void main() {
  final helpTexts = <String Function(AppStrings s)>[
    (s) => s.helpTitle,
    (s) => s.helpTooltip,
    (s) => s.helpSectionOverview,
    (s) => s.helpOverviewBody,
    (s) => s.helpSectionTabs,
    (s) => s.helpTabsBody,
    (s) => s.helpSectionEmbedSteps,
    (s) => s.helpEmbedStep1,
    (s) => s.helpEmbedStep2,
    (s) => s.helpEmbedStep3,
    (s) => s.helpEmbedStep4,
    (s) => s.helpEmbedStep5,
    (s) => s.helpEmbedStep6,
    (s) => s.helpEmbedStep7,
    (s) => s.helpEmbedStep8,
    (s) => s.helpSectionExtractSteps,
    (s) => s.helpExtractStep1,
    (s) => s.helpExtractStep2,
    (s) => s.helpExtractStep3,
    (s) => s.helpExtractStep4,
    (s) => s.helpExtractStep5,
    (s) => s.helpExtractStep6,
    (s) => s.helpSectionTips,
    (s) => s.helpTipsBody,
    (s) => s.helpClose,
  ];

  for (final locale in AppLocale.values) {
    test('help strings non-empty for $locale', () {
      final s = AppStrings(locale);
      for (final text in helpTexts) {
        expect(text(s).trim(), isNotEmpty, reason: 'locale=$locale');
      }
    });
  }

  test('helpTitle is localized (fa vs en vs ar vs fr)', () {
    final fa = AppStrings(AppLocale.fa).helpTitle;
    final en = AppStrings(AppLocale.en).helpTitle;
    final ar = AppStrings(AppLocale.ar).helpTitle;
    final fr = AppStrings(AppLocale.fr).helpTitle;
    expect(fa, isNot(equals(en)));
    expect(fa, isNot(equals(ar)));
    expect(fa, isNot(equals(fr)));
    expect(en, isNot(equals(ar)));
    expect(en, isNot(equals(fr)));
  });
}
