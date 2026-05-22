import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/about/about_screen.dart';
import '../features/embed/embed_screen.dart';
import '../features/extract/extract_screen.dart';
import '../features/settings/settings_screen.dart';
import 'app_strings.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

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
    final destinations = [
      _Dest(Icons.shield_outlined, Icons.shield, s.embedTab),
      _Dest(Icons.search_outlined, Icons.search, s.extractTab),
      _Dest(Icons.settings_outlined, Icons.settings, s.settingsTab),
      _Dest(Icons.groups_outlined, Icons.groups, s.aboutUsTab),
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
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
    );
    return scaffold;
  }
}

class _Dest {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _Dest(this.icon, this.selectedIcon, this.label);
}
