import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;
  final Color seedColor;
  final double r;
  final double x0;

  const AppSettings({
    required this.themeMode,
    required this.locale,
    required this.seedColor,
    required this.r,
    required this.x0,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    Color? seedColor,
    double? r,
    double? x0,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      seedColor: seedColor ?? this.seedColor,
      r: r ?? this.r,
      x0: x0 ?? this.x0,
    );
  }

  static const AppSettings defaults = AppSettings(
    themeMode: ThemeMode.system,
    locale: Locale('fa'),
    seedColor: Color(0xFF6750A4),
    r: 3.99,
    x0: 0.45,
  );
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(AppSettings.defaults) {
    _load();
  }

  static const _kTheme = 'theme';
  static const _kLocale = 'locale';
  static const _kSeed = 'seed';
  static const _kR = 'logistic_r';
  static const _kX0 = 'logistic_x0';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = AppSettings(
      themeMode: _themeFromString(p.getString(_kTheme) ?? 'system'),
      locale: Locale(p.getString(_kLocale) ?? 'fa'),
      seedColor: Color(p.getInt(_kSeed) ?? AppSettings.defaults.seedColor.toARGB32()),
      r: p.getDouble(_kR) ?? 3.99,
      x0: p.getDouble(_kX0) ?? 0.45,
    );
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
    state = state.copyWith(r: r);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kR, r);
  }

  Future<void> setLogisticX0(double x0) async {
    state = state.copyWith(x0: x0);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kX0, x0);
  }

  Future<void> resetToDefaults() async {
    state = AppSettings.defaults;
    final p = await SharedPreferences.getInstance();
    await p.clear();
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

final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) => SettingsController());
