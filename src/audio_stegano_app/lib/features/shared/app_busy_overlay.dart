import 'package:flutter/material.dart';

import '../../app/app_ui_tokens.dart';

/// Full-viewport blocking busy layer — absorbs all pointer input until dismissed.
class AppBusyOverlay extends StatelessWidget {
  const AppBusyOverlay({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Semantics(
          liveRegion: true,
          label: message,
          child: ColoredBox(
            color: scheme.scrim.withValues(alpha: 0.48),
            child: Center(
              child: Material(
                color: scheme.surface,
                elevation: 8,
                shadowColor: scheme.shadow.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppUiTokens.radiusCard),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
