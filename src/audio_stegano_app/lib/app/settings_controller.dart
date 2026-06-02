import 'package:flutter/material.dart';

import 'package:flutter_riverpod/legacy.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/stego/stego_embed_mode.dart';
import 'app_config.dart';
import 'app_config_provider.dart';
import 'logistic_param_bounds.dart';

class AppSettings {
  final ThemeMode themeMode;

  final Locale locale;

  final bool localeConfigured;

  final bool usageGuideSeen;

  final Color seedColor;

  final double r;

  final double x0;

  final bool defaultFixedMessageBitLimit;

  final StegoEmbedMode stegoEmbedMode;

  const AppSettings({
    required this.themeMode,

    required this.locale,

    required this.localeConfigured,

    required this.usageGuideSeen,

    required this.seedColor,

    required this.r,

    required this.x0,

    required this.defaultFixedMessageBitLimit,
    required this.stegoEmbedMode,
  });

  factory AppSettings.fromDeploy(AppConfig deploy) => AppSettings(
    themeMode: ThemeMode.system,

    locale: const Locale('fa'),

    localeConfigured: false,

    usageGuideSeen: false,

    seedColor: const Color(0xFF00B4B7),

    r: LogisticParamBounds.clampR(deploy.logisticR),

    x0: LogisticParamBounds.clampX0(deploy.logisticX0),

    defaultFixedMessageBitLimit: true,
    stegoEmbedMode: deploy.defaultStegoEmbedMode,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,

    Locale? locale,

    bool? localeConfigured,

    bool? usageGuideSeen,

    Color? seedColor,

    double? r,

    double? x0,

    bool? defaultFixedMessageBitLimit,
    StegoEmbedMode? stegoEmbedMode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,

      locale: locale ?? this.locale,

      localeConfigured: localeConfigured ?? this.localeConfigured,

      usageGuideSeen: usageGuideSeen ?? this.usageGuideSeen,

      seedColor: seedColor ?? this.seedColor,

      r: r ?? this.r,

      x0: x0 ?? this.x0,

      defaultFixedMessageBitLimit:
          defaultFixedMessageBitLimit ?? this.defaultFixedMessageBitLimit,
      stegoEmbedMode: stegoEmbedMode ?? this.stegoEmbedMode,
    );
  }
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._deploy) : super(AppSettings.fromDeploy(_deploy)) {
    _hydrate = _load();
  }

  final AppConfig _deploy;

  Future<void>? _hydrate;

  /// Waits until [SharedPreferences] values are applied to [state].

  Future<void> waitForHydrate() => _hydrate ??= _load();

  static const _kTheme = 'theme';

  static const _kLocale = 'locale';

  static const _kLocaleConfigured = 'locale_configured';

  static const _kUsageGuideSeen = 'usage_guide_seen';

  static const _kSeed = 'seed';

  static const _kR = 'logistic_r';

  static const _kX0 = 'logistic_x0';

  static const _kDefaultFixedMsgBitLimit = 'default_fixed_msg_bit_limit';

  static const _kStegoEmbedMode = 'stego_embed_mode';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();

    final localeConfigured =
        p.getBool(_kLocaleConfigured) ?? p.containsKey(_kLocale);

    final fromDeploy = AppSettings.fromDeploy(_deploy);

    state = AppSettings(
      themeMode: _themeFromString(p.getString(_kTheme) ?? 'system'),

      locale: Locale(p.getString(_kLocale) ?? 'fa'),

      localeConfigured: localeConfigured,

      usageGuideSeen: p.getBool(_kUsageGuideSeen) ?? false,

      seedColor: Color(p.getInt(_kSeed) ?? fromDeploy.seedColor.toARGB32()),

      r: LogisticParamBounds.clampR(p.getDouble(_kR) ?? _deploy.logisticR),

      x0: LogisticParamBounds.clampX0(p.getDouble(_kX0) ?? _deploy.logisticX0),

      defaultFixedMessageBitLimit: p.getBool(_kDefaultFixedMsgBitLimit) ?? true,
      stegoEmbedMode: StegoEmbedModeJson.fromConfig(
        p.getString(_kStegoEmbedMode) ?? _deploy.defaultStegoEmbedMode.configValue,
      ),
    );
  }

  /// First-run usage guide; persisted so the screen is not shown again.

  Future<void> completeUsageGuideOnboarding() async {
    final p = await SharedPreferences.getInstance();

    await p.setBool(_kUsageGuideSeen, true);

    state = state.copyWith(usageGuideSeen: true);
  }

  /// First-run language choice; persisted so the picker is not shown again.

  Future<void> completeLocaleOnboarding(Locale locale) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(_kLocale, locale.languageCode);

    await p.setBool(_kLocaleConfigured, true);

    state = state.copyWith(locale: locale, localeConfigured: true);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);

    final p = await SharedPreferences.getInstance();

    await p.setString(_kTheme, _themeToString(mode));
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);

    final p = await SharedPreferences.getInstance();

    await p.setString(_kLocale, locale.languageCode);
  }

  Future<void> setSeedColor(Color c) async {
    state = state.copyWith(seedColor: c);

    final p = await SharedPreferences.getInstance();

    await p.setInt(_kSeed, c.toARGB32());
  }

  Future<void> setLogisticR(double r) async {
    final clamped = LogisticParamBounds.clampR(r);

    state = state.copyWith(r: clamped);

    final p = await SharedPreferences.getInstance();

    await p.setDouble(_kR, clamped);
  }

  Future<void> setLogisticX0(double x0) async {
    final clamped = LogisticParamBounds.clampX0(x0);

    state = state.copyWith(x0: clamped);

    final p = await SharedPreferences.getInstance();

    await p.setDouble(_kX0, clamped);
  }

  Future<void> setStegoEmbedMode(StegoEmbedMode mode) async {
    state = state.copyWith(stegoEmbedMode: mode);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kStegoEmbedMode, mode.configValue);
  }

  Future<void> setDefaultFixedMessageBitLimit(bool enabled) async {
    state = state.copyWith(defaultFixedMessageBitLimit: enabled);

    final p = await SharedPreferences.getInstance();

    await p.setBool(_kDefaultFixedMsgBitLimit, enabled);
  }

  Future<void> resetToDefaults() async {
    final p = await SharedPreferences.getInstance();

    await p.clear();

    state = AppSettings.fromDeploy(_deploy);

    _hydrate = _load();

    await _hydrate;
  }

  String _themeToString(ThemeMode m) => switch (m) {
    ThemeMode.light => 'light',

    ThemeMode.dark => 'dark',

    ThemeMode.system => 'system',
  };

  ThemeMode _themeFromString(String s) => switch (s) {
    'light' => ThemeMode.light,

    'dark' => ThemeMode.dark,

    _ => ThemeMode.system,
  };
}

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) => SettingsController(ref.watch(appConfigProvider)),
);
