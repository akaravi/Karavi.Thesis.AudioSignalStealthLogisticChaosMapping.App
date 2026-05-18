import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_strings.dart';
import '../../app/settings_controller.dart';
import '../shared/tab_scroll_body.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final s = AppStrings.of(context);
    return TabScrollBody(
      children: [
        _section(context, s.themeMode, [
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(s.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(s.themeDark),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.settings_brightness_outlined),
                label: Text(s.themeSystem),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (set) => ctrl.setTheme(set.first),
          ),
        ]),
        _section(context, s.language, [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'fa', label: Text(s.persian)),
              ButtonSegment(value: 'en', label: Text(s.english)),
            ],
            selected: {settings.locale.languageCode},
            onSelectionChanged: (set) => ctrl.setLocale(Locale(set.first)),
          ),
        ]),
        _section(context, s.colorSeed, [
          Wrap(
            spacing: 12,
            children:
                const [
                  Color(0xFF6750A4),
                  Color(0xFF1B73E8),
                  Color(0xFF2E7D32),
                  Color(0xFFE65100),
                  Color(0xFFC62828),
                  Color(0xFF455A64),
                ].map((c) {
                  return GestureDetector(
                    onTap: () => ctrl.setSeedColor(c),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: settings.seedColor.toARGB32() == c.toARGB32()
                            ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ]),
        _section(context, s.logisticParams, [
          ListTile(
            title: Text(s.rParam),
            subtitle: Slider(
              value: settings.r,
              min: 3.5,
              max: 4.0,
              divisions: 50,
              label: settings.r.toStringAsFixed(3),
              onChanged: (v) => ctrl.setLogisticR(v),
            ),
            trailing: Text(settings.r.toStringAsFixed(3)),
          ),
          ListTile(
            title: Text(s.x0Param),
            subtitle: Slider(
              value: settings.x0,
              min: 0.01,
              max: 0.99,
              divisions: 98,
              label: settings.x0.toStringAsFixed(2),
              onChanged: (v) => ctrl.setLogisticX0(v),
            ),
            trailing: Text(settings.x0.toStringAsFixed(2)),
          ),
        ]),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: ctrl.resetToDefaults,
            icon: const Icon(Icons.restart_alt),
            label: Text(s.reset),
          ),
        ),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
