import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final pages = const [EmbedScreen(), ExtractScreen(), SettingsScreen()];
    final destinations = [
      _Dest(Icons.shield_outlined, Icons.shield, s.embedTab),
      _Dest(Icons.search_outlined, Icons.search, s.extractTab),
      _Dest(Icons.settings_outlined, Icons.settings, s.settingsTab),
    ];

    // Stack of Offstage pages keeps each tab's state alive while removing
    // hidden ones from layout, hit-testing, AND the semantics tree. This
    // sidesteps the noisy `accessibility_bridge.cc` AXTree warning that
    // IndexedStack triggers on Flutter Windows.
    final body = Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < pages.length; i++)
          Offstage(
            offstage: i != _index,
            child: ExcludeSemantics(
              excluding: i != _index,
              child: TickerMode(enabled: i == _index, child: pages[i]),
            ),
          ),
      ],
    );
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: s.aboutTitle,
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context, s),
          ),
        ],
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

  Future<void> _showAboutDialog(BuildContext context, AppStrings s) async {
    final theme = Theme.of(context);
    showAboutDialog(
      context: context,
      applicationName: s.appTitle,
      applicationVersion: '1.0.0',
      applicationLegalese: s.aboutThesis,
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.graphic_eq,
          color: theme.colorScheme.onPrimary,
          size: 36,
        ),
      ),
      children: [
        const SizedBox(height: 8),
        _aboutRow(theme, Icons.person_outline, s.aboutAuthor, 'Karavi'),
        const SizedBox(height: 8),
        _aboutRow(
          theme,
          Icons.functions,
          s.aboutAlgo,
          s.aboutAlgoBody,
          multiline: true,
        ),
      ],
    );
  }

  Widget _aboutRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    bool multiline = false,
  }) {
    return Row(
      crossAxisAlignment: multiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dest {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _Dest(this.icon, this.selectedIcon, this.label);
}
