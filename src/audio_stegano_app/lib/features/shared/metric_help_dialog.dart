import 'package:flutter/material.dart';

import '../../app/app_strings.dart';
import '../../app/metric_help_strings.dart';
import 'embed_metric_kind.dart';

/// Full multilingual explanation for one embed quality metric.
Future<void> showMetricHelpDialog(
  BuildContext context,
  EmbedMetricKind kind,
) {
  final s = AppStrings.of(context);
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  return showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        icon: Icon(
          Icons.analytics_outlined,
          color: scheme.primary,
          size: 28,
        ),
        title: Text(s.metricHelpTitle(kind)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 360),
          child: SingleChildScrollView(
            child: Text(
              s.metricHelpBody(kind),
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(s.helpClose),
          ),
        ],
      );
    },
  );
}
