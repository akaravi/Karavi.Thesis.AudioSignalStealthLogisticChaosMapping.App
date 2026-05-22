import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_strings.dart';
import '../../app/settings_controller.dart';

/// Shown only until the user picks a language once ([SettingsController.completeLocaleOnboarding]).
class LanguageOnboardingScreen extends ConsumerWidget {
  final VoidCallback onComplete;

  const LanguageOnboardingScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary.withValues(alpha: 0.12), scheme.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Icon(Icons.translate, size: 52, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  s.language,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.chooseLanguage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _LanguageCard(
                          title: s.persian,
                          subtitle: 'Persian — FA',
                          icon: Icons.format_textdirection_r_to_l,
                          onTap: () =>
                              _select(context, ref, const Locale('fa')),
                        ),
                        const SizedBox(height: 12),
                        _LanguageCard(
                          title: s.english,
                          subtitle: 'English — EN',
                          icon: Icons.format_textdirection_l_to_r,
                          onTap: () =>
                              _select(context, ref, const Locale('en')),
                        ),
                        const SizedBox(height: 12),
                        _LanguageCard(
                          title: s.arabic,
                          subtitle: 'Arabic — AR',
                          icon: Icons.format_textdirection_r_to_l,
                          onTap: () =>
                              _select(context, ref, const Locale('ar')),
                        ),
                        const SizedBox(height: 12),
                        _LanguageCard(
                          title: s.french,
                          subtitle: 'French — FR',
                          icon: Icons.format_textdirection_l_to_r,
                          onTap: () =>
                              _select(context, ref, const Locale('fr')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    Locale locale,
  ) async {
    await ref.read(settingsProvider.notifier).completeLocaleOnboarding(locale);
    if (!context.mounted) return;
    onComplete();
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
