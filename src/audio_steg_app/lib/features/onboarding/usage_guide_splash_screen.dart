import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_strings.dart';
import '../../app/settings_controller.dart';

/// One-time guide after language selection: purpose and how to use the app.
class UsageGuideSplashScreen extends ConsumerWidget {
  final VoidCallback onComplete;

  const UsageGuideSplashScreen({super.key, required this.onComplete});

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
            colors: [
              scheme.primary.withValues(alpha: 0.14),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Icon(
                        Icons.menu_book_outlined,
                        size: 52,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.usageGuideTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            s.usageGuidePurpose,
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                              height: 1.55,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _GuideStep(
                        icon: Icons.shield_outlined,
                        text: s.usageGuideStepEmbed,
                      ),
                      _GuideStep(
                        icon: Icons.search_outlined,
                        text: s.usageGuideStepExtract,
                      ),
                      _GuideStep(
                        icon: Icons.settings_outlined,
                        text: s.usageGuideStepSettings,
                      ),
                      _GuideStep(
                        icon: Icons.groups_outlined,
                        text: s.usageGuideStepAbout,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: FilledButton(
                  onPressed: () => _continue(context, ref),
                  child: Text(s.usageGuideContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    await ref.read(settingsProvider.notifier).completeUsageGuideOnboarding();
    if (!context.mounted) return;
    onComplete();
  }
}

class _GuideStep extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GuideStep({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.onPrimaryContainer, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
