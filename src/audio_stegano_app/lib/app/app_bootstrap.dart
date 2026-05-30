import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/platform/android_widget_capture_launch.dart';
import '../core/platform/widget_capture_launch.dart';
import '../features/onboarding/language_onboarding_screen.dart';
import '../features/onboarding/splash_flow_screen.dart';
import '../features/onboarding/usage_guide_splash_screen.dart';
import '../features/widget/widget_capture_screen.dart';
import 'home_shell.dart';
import 'settings_controller.dart';

/// Cold start: main splash → one-time language → one-time usage guide → home.
class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  bool _hydrated = false;
  bool _splashDone = false;
  WidgetCaptureLaunch? _widgetCaptureLaunch;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final capture = await AndroidWidgetCaptureLaunchBridge.consumeInitial();
    await ref.read(settingsProvider.notifier).waitForHydrate();
    if (mounted) {
      setState(() {
        _widgetCaptureLaunch = capture;
        _hydrated = true;
      });
    }
  }

  void _onLanguageDone() => setState(() {});

  void _onUsageGuideDone() => setState(() {});

  void _onSplashDone() => setState(() => _splashDone = true);

  @override
  Widget build(BuildContext context) {
    if (!_hydrated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final widgetCapture = _widgetCaptureLaunch;
    if (widgetCapture != null) {
      return WidgetCaptureScreen(initialAction: widgetCapture.action);
    }

    final settings = ref.watch(settingsProvider);

    if (!_splashDone) {
      return SplashFlowScreen(onComplete: _onSplashDone);
    }

    if (!settings.localeConfigured) {
      return LanguageOnboardingScreen(onComplete: _onLanguageDone);
    }

    if (!settings.usageGuideSeen) {
      return UsageGuideSplashScreen(onComplete: _onUsageGuideDone);
    }

    return const HomeShell();
  }
}
