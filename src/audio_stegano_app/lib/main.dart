import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_bootstrap.dart';
import 'app/app_config.dart';
import 'app/app_version.dart';
import 'app/app_config_provider.dart';
import 'app/app_locale.dart';
import 'app/app_strings.dart';
import 'app/app_theme.dart';
import 'app/session_log.dart';
import 'app/settings_controller.dart';
import 'core/platform/platform.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    SessionLog.write(
      'FlutterError',
      error: details.exception,
      stack: details.stack,
    );
  };

  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SessionLog.init();
      await AppVersion.load();
      SessionLog.write('App starting');
      final appConfig = await AppConfig.load();
      runApp(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(appConfig)],
          child: const AudioStegApp(),
        ),
      );
    },
    (error, stack) {
      SessionLog.write('UncaughtZonedError', error: error, stack: stack);
    },
  );
}

class AudioStegApp extends ConsumerWidget {
  const AudioStegApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final strings = AppStrings(
      AppLocaleCodes.fromLanguageCode(settings.locale.languageCode),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: strings.appTitle,
      themeMode: settings.themeMode,
      theme: AppTheme.light(settings.seedColor),
      darkTheme: AppTheme.dark(settings.seedColor),
      locale: settings.locale,
      supportedLocales: const [
        Locale('fa'),
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final rtl = AppLocaleCodes.fromLanguageCode(
          Localizations.localeOf(context).languageCode,
        ).isRtl;
        Widget tree = Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
        // Win32 embedder: rapid semantics updates (RTL nav + live waveform) can
        // corrupt AXTree and terminate the process (accessibility_bridge.cc).
        if (isNativeWindows) {
          tree = ExcludeSemantics(child: tree);
        }
        return tree;
      },
      home: const AppBootstrap(),
    );
  }
}
