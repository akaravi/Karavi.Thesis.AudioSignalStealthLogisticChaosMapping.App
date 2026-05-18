import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_theme.dart';
import 'app/home_shell.dart';
import 'app/session_log.dart';
import 'app/settings_controller.dart';

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
      SessionLog.write('App starting');
      runApp(const ProviderScope(child: AudioStegApp()));
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Audio Steganography',
      themeMode: settings.themeMode,
      theme: AppTheme.light(settings.seedColor),
      darkTheme: AppTheme.dark(settings.seedColor),
      locale: settings.locale,
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final isFa = Localizations.localeOf(context).languageCode == 'fa';
        return Directionality(
          textDirection: isFa ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeShell(),
    );
  }
}
