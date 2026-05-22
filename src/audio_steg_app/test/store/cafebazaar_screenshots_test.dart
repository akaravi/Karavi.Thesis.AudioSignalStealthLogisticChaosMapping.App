import 'package:audio_steg_app/app/app_config.dart';
import 'package:audio_steg_app/app/app_config_provider.dart';
import 'package:audio_steg_app/app/app_locale.dart';
import 'package:audio_steg_app/app/app_strings.dart';
import 'package:audio_steg_app/app/app_theme.dart';
import 'package:audio_steg_app/app/home_shell.dart';
import 'package:audio_steg_app/app/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generates store screenshots under [goldensDir] (1080×1920 @ 3x → phone layout).
/// Relative to this test file → [test/goldens/cafebazaar].
const goldensDir = '../goldens/cafebazaar';

void _mockPrefs({ThemeMode theme = ThemeMode.light}) {
  SharedPreferences.setMockInitialValues({
    'theme': switch (theme) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    },
    'locale': 'fa',
    'locale_configured': true,
    'usage_guide_seen': true,
    'seed': const Color(0xFF00B4B7).toARGB32(),
    'logistic_r': AppConfig.defaults.logisticR,
    'logistic_x0': AppConfig.defaults.logisticX0,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpStoreApp(
    WidgetTester tester, {
    ThemeMode theme = ThemeMode.light,
  }) async {
    _mockPrefs(theme: theme);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(AppConfig.defaults)],
        child: const _StoreMaterialApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  Future<void> tapBottomTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('Cafe Bazaar screenshots', () {
    testWidgets('01 embed — light fa', (tester) async {
      await pumpStoreApp(tester);
      await tester.enterText(
        find.byType(TextField).first,
        'این یک پیام نمونه برای نمایش در فروشگاه است.',
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$goldensDir/01_embed_fa_light.png'),
      );
    });

    testWidgets('02 extract — light fa', (tester) async {
      await pumpStoreApp(tester);
      final s = AppStrings(AppLocale.fa);
      await tapBottomTab(tester, s.extractTab);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$goldensDir/02_extract_fa_light.png'),
      );
    });

    testWidgets('03 settings — light fa', (tester) async {
      await pumpStoreApp(tester);
      final s = AppStrings(AppLocale.fa);
      await tapBottomTab(tester, s.settingsTab);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$goldensDir/03_settings_fa_light.png'),
      );
    });

    testWidgets('04 about — light fa', (tester) async {
      await pumpStoreApp(tester);
      final s = AppStrings(AppLocale.fa);
      await tapBottomTab(tester, s.aboutUsTab);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$goldensDir/04_about_fa_light.png'),
      );
    });

    testWidgets('05 embed — dark fa', (tester) async {
      await pumpStoreApp(tester, theme: ThemeMode.dark);
      await tester.enterText(
        find.byType(TextField).first,
        'پیام مخفی در موج صدا — صوت‌نهان',
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$goldensDir/05_embed_fa_dark.png'),
      );
    });
  });
}

class _StoreMaterialApp extends ConsumerWidget {
  const _StoreMaterialApp();

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
        return Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeShell(),
    );
  }
}
