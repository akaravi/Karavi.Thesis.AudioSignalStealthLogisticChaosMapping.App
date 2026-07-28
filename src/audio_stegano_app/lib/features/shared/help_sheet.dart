import 'package:flutter/material.dart';

import '../../app/app_strings.dart';

/// Detailed in-app help shown as a modal bottom sheet.
///
/// Sections: overview, tabs, embed steps, extract steps, important tips.
/// Initial section is highlighted by [initialSection]; the sheet is fully
/// scrollable on small screens (DraggableScrollableSheet).
enum HelpSection { embed, extract }

Future<void> showHelpSheet(
  BuildContext context, {
  HelpSection initialSection = HelpSection.embed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _HelpSheetBody(initialSection: initialSection),
  );
}

class _HelpSheetBody extends StatelessWidget {
  const _HelpSheetBody({required this.initialSection});

  final HelpSection initialSection;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final embedSteps = <String>[
      s.helpEmbedStep1,
      s.helpEmbedStep2,
      s.helpEmbedStep3,
      s.helpEmbedStep4,
      s.helpEmbedStep5,
      s.helpEmbedStep6,
      s.helpEmbedStep7,
      s.helpEmbedStep8,
    ];
    final extractSteps = <String>[
      s.helpExtractStep1,
      s.helpExtractStep2,
      s.helpExtractStep3,
      s.helpExtractStep4,
      s.helpExtractStep5,
      s.helpExtractStep6,
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.menu_book_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.helpTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: s.helpClose,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _HelpCard(
                    icon: Icons.audio_file_outlined,
                    title: s.helpSectionOverview,
                    body: s.helpOverviewBody,
                  ),
                  const SizedBox(height: 12),
                  _HelpCard(
                    icon: Icons.dashboard_outlined,
                    title: s.helpSectionTabs,
                    body: s.helpTabsBody,
                  ),
                  const SizedBox(height: 12),
                  _HelpStepsCard(
                    icon: Icons.shield_outlined,
                    title: s.helpSectionEmbedSteps,
                    steps: embedSteps,
                    highlighted: initialSection == HelpSection.embed,
                  ),
                  const SizedBox(height: 12),
                  _HelpStepsCard(
                    icon: Icons.lock_open_outlined,
                    title: s.helpSectionExtractSteps,
                    steps: extractSteps,
                    highlighted: initialSection == HelpSection.extract,
                  ),
                  const SizedBox(height: 12),
                  _HelpCard(
                    icon: Icons.lightbulb_outline,
                    title: s.helpSectionTips,
                    body: s.helpTipsBody,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.center,
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(s.helpClose),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpStepsCard extends StatelessWidget {
  const _HelpStepsCard({
    required this.icon,
    required this.title,
    required this.steps,
    required this.highlighted,
  });

  final IconData icon;
  final String title;
  final List<String> steps;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = highlighted
        ? scheme.primary.withValues(alpha: 0.65)
        : scheme.outlineVariant.withValues(alpha: 0.4);
    final headerColor = highlighted ? scheme.primaryContainer : null;
    return Card(
      color: highlighted
          ? scheme.surfaceContainerHighest
          : scheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor, width: highlighted ? 1.4 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: highlighted
                        ? scheme.onPrimaryContainer
                        : scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: highlighted
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final step in steps) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.7,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
