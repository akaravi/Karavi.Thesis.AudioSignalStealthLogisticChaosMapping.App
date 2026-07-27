import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/playback_hub.dart';
import '../core/platform/android_open_file_intent.dart';
import '../core/platform/desktop_open_audio_args.dart';
import '../core/platform/windows_open_file_intent.dart';
import 'session_log.dart';
import '../features/about/about_screen.dart';
import '../features/embed/embed_screen.dart';
import '../features/extract/extract_screen.dart';
import '../features/settings/settings_screen.dart';
import 'app_icon_accents.dart';
import 'app_strings.dart';
import 'busy_overlay_provider.dart';
import 'opened_audio_file.dart';
import 'pending_open_audio_provider.dart';
import '../features/shared/accent_icon.dart';
import '../features/shared/app_busy_overlay.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  StreamSubscription<OpenedAudioFile>? _androidOpenSub;
  StreamSubscription<OpenedAudioFile>? _windowsOpenSub;

  static const _extractTabIndex = 1;

  void _selectTab(int i) {
    if (i == _index) return;
    if (ref.read(appBusyMessageProvider) != null) return;
    final leaving = _index;
    if (leaving == 0) {
      unawaited(PlaybackHub.instance.stopSessions(PlaybackHub.embedSessions));
    } else if (leaving == _extractTabIndex) {
      unawaited(PlaybackHub.instance.stopSessions(PlaybackHub.extractSessions));
    }
    setState(() => _index = i);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_bindAndroidOpenWith());
    unawaited(_bindDesktopOpenWith());
    unawaited(_bindWindowsOpenWith());
  }

  Future<void> _bindWindowsOpenWith() async {
    if (!WindowsOpenFileIntent.isSupported) return;
    _windowsOpenSub = WindowsOpenFileIntent.watchOpens().listen((file) {
      SessionLog.write('Open with (pipe): ${file.path}');
      _scheduleOpenFile(file);
    });
  }

  Future<void> _bindDesktopOpenWith() async {
    final initial = DesktopOpenAudioArgs.consumeInitial();
    if (initial != null) {
      SessionLog.write('Open with: ${initial.path}');
      _scheduleOpenFile(initial);
    }
  }

  Future<void> _bindAndroidOpenWith() async {
    final initial = await AndroidOpenFileIntent.consumeInitial();
    if (initial != null) {
      _scheduleOpenFile(initial);
    }
    _androidOpenSub = AndroidOpenFileIntent.watchOpens().listen(
      _scheduleOpenFile,
    );
  }

  void _scheduleOpenFile(OpenedAudioFile file) {
    if (!mounted) return;
    ref.read(pendingOpenAudioFileProvider.notifier).setPending(file);
    _selectTab(_extractTabIndex);
  }

  @override
  void dispose() {
    unawaited(_androidOpenSub?.cancel());
    unawaited(_windowsOpenSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final wide = MediaQuery.of(context).size.width >= 720;
    final pages = const [
      EmbedScreen(),
      ExtractScreen(),
      SettingsScreen(),
      AboutScreen(),
    ];
    // Semantic accents: embed violet · extract teal · settings amber · about rose.
    final destinations = [
      _Dest(
        Icons.layers_outlined,
        Icons.layers,
        s.embedTab,
        AppIconAccent.embed,
      ),
      _Dest(
        Icons.search_outlined,
        Icons.search,
        s.extractTab,
        AppIconAccent.extract,
      ),
      _Dest(
        Icons.settings_outlined,
        Icons.settings,
        s.settingsTab,
        AppIconAccent.settings,
      ),
      _Dest(
        Icons.person_outline,
        Icons.person,
        s.aboutUsTab,
        AppIconAccent.about,
      ),
    ];

    // Stack of Offstage pages keeps each tab's state alive while removing
    // hidden ones from layout, hit-testing, AND the semantics tree. This
    // sidesteps the noisy `accessibility_bridge.cc` AXTree warning that
    // IndexedStack triggers on Flutter Windows.
    final body = Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < pages.length; i++)
          Positioned.fill(
            child: Offstage(
              offstage: i != _index,
              child: ExcludeSemantics(
                excluding: i != _index,
                child: TickerMode(enabled: i == _index, child: pages[i]),
              ),
            ),
          ),
      ],
    );
    final scheme = Theme.of(context).colorScheme;
    final busyMessage = ref.watch(appBusyMessageProvider);
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: scheme.surfaceContainer,
                  indicatorColor: scheme.primaryContainer,
                  onDestinationSelected:
                      busyMessage != null ? (_) {} : _selectTab,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: AccentIcon(
                          d.icon,
                          accent: d.accent,
                          selected: false,
                        ),
                        selectedIcon: AccentIcon(
                          d.selectedIcon,
                          accent: d.accent,
                        ),
                        label: Text(d.label),
                      ),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  color: scheme.outlineVariant,
                ),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected:
                  busyMessage != null ? (_) {} : _selectTab,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: AccentIcon(
                      d.icon,
                      accent: d.accent,
                      selected: false,
                    ),
                    selectedIcon: AccentIcon(
                      d.selectedIcon,
                      accent: d.accent,
                    ),
                    label: d.label,
                  ),
              ],
            ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        scaffold,
        if (busyMessage != null) AppBusyOverlay(message: busyMessage),
      ],
    );
  }
}

class _Dest {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final AppIconAccent accent;
  const _Dest(this.icon, this.selectedIcon, this.label, this.accent);
}
