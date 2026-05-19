import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_strings.dart';
import '../../app/logistic_param_bounds.dart';
import '../../app/settings_controller.dart';
import '../shared/logistic_param_field.dart';
import '../shared/tab_scroll_body.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _languageCodes = ['fa', 'en', 'ar', 'fr'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    String labelFor(String code) => switch (code) {
      'fa' => s.persian,
      'en' => s.english,
      'ar' => s.arabic,
      'fr' => s.french,
      _ => code,
    };

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final code in _languageCodes)
                FilterChip(
                  label: Text(labelFor(code)),
                  selected: settings.locale.languageCode == code,
                  onSelected: (_) => ctrl.setLocale(Locale(code)),
                  selectedColor: scheme.primaryContainer,
                  checkmarkColor: scheme.onPrimaryContainer,
                ),
            ],
          ),
        ]),
        _section(context, s.colorSeed, [
          Wrap(
            spacing: 12,
            children:
                const [
                  Color(0xFF00B4B7),
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
                            ? Border.all(color: scheme.onSurface, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ]),
        _section(context, s.logisticParams, [
          LogisticParamField(
            label: s.rParam,
            rangeHint: s.logisticRRangeHint,
            invalidHint: s.logisticInvalidValue,
            value: settings.r,
            min: LogisticParamBounds.rMin,
            max: LogisticParamBounds.rMax,
            divisions: 50,
            fractionDigits: 3,
            onChanged: ctrl.setLogisticR,
          ),
          const SizedBox(height: 8),
          LogisticParamField(
            label: s.x0Param,
            rangeHint: s.logisticX0RangeHint,
            invalidHint: s.logisticInvalidValue,
            value: settings.x0,
            min: LogisticParamBounds.x0Min,
            max: LogisticParamBounds.x0Max,
            divisions: 98,
            fractionDigits: 2,
            onChanged: ctrl.setLogisticX0,
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: scheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
