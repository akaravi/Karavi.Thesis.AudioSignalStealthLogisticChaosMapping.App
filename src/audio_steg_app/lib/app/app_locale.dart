/// Supported UI locales (Persian is the project base language).
enum AppLocale { fa, en, ar, fr }

extension AppLocaleCodes on AppLocale {
  String get languageCode => switch (this) {
        AppLocale.fa => 'fa',
        AppLocale.en => 'en',
        AppLocale.ar => 'ar',
        AppLocale.fr => 'fr',
      };

  static AppLocale fromLanguageCode(String code) => switch (code) {
        'en' => AppLocale.en,
        'ar' => AppLocale.ar,
        'fr' => AppLocale.fr,
        _ => AppLocale.fa,
      };

  bool get isRtl => this == AppLocale.fa || this == AppLocale.ar;
}
