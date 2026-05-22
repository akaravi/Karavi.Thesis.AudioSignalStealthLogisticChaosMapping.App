import 'package:flutter/material.dart';

import '../../app/app_strings.dart';

/// User-facing embed warning (capacity, empty text, etc.) in a modal dialog.
Future<void> showEmbedWarningDialog(
  BuildContext context,
  String message, {
  String? title,
}) {
  final s = AppStrings.of(context);
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final dialogTitle = title ?? s.embedWarningTitle;

  return showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: scheme.error, size: 32),
        title: Text(dialogTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: scheme.onSurface,
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
