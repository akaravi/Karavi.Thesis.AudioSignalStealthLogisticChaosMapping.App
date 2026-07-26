import 'package:flutter/material.dart';

import '../../app/app_ui_tokens.dart';

/// Circular toolbar FAB — primary (new) or secondary (help), shared by Embed/Extract.
class PageToolbarFab extends StatelessWidget {
  const PageToolbarFab({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.primary = true,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = primary ? scheme.primaryContainer : scheme.secondaryContainer;
    final fg =
        primary ? scheme.onPrimaryContainer : scheme.onSecondaryContainer;
    return Material(
      elevation: 4,
      shadowColor: scheme.shadow.withValues(alpha: 0.4),
      color: bg,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: fg),
      ),
    );
  }
}

/// Top-end help + optional primary action row (RTL-safe via [AlignmentDirectional]).
class PageToolbarFabRow extends StatelessWidget {
  const PageToolbarFabRow({
    super.key,
    required this.helpTooltip,
    required this.onHelp,
    this.primaryTooltip,
    this.primaryIcon,
    this.onPrimary,
    this.primaryEnabled = true,
  });

  final String helpTooltip;
  final VoidCallback onHelp;
  final String? primaryTooltip;
  final IconData? primaryIcon;
  final VoidCallback? onPrimary;
  final bool primaryEnabled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (primaryTooltip != null && primaryIcon != null) ...[
            PageToolbarFab(
              tooltip: primaryTooltip!,
              icon: primaryIcon!,
              onPressed: primaryEnabled ? onPrimary : null,
              primary: true,
            ),
            const SizedBox(width: AppUiTokens.toolbarFabGap),
          ],
          PageToolbarFab(
            tooltip: helpTooltip,
            icon: Icons.help_outline_rounded,
            onPressed: onHelp,
            primary: false,
          ),
        ],
      ),
    );
  }
}
