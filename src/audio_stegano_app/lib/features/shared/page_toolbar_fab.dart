import 'package:flutter/material.dart';

import '../../app/app_icon_accents.dart';
import '../../app/app_ui_tokens.dart';

/// Circular toolbar FAB — semantic accent colors + soft glow.
class PageToolbarFab extends StatelessWidget {
  const PageToolbarFab({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.primary = true,
    this.accent,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  /// Overrides default create/help mapping when set.
  final AppIconAccent? accent;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final resolved = accent ??
        (primary ? AppIconAccent.create : AppIconAccent.help);
    final fg = AppIconAccents.foreground(resolved, brightness);
    final bg = AppIconAccents.container(resolved, brightness);
    final disabled = onPressed == null;
    return Material(
      elevation: disabled ? 0 : 4,
      shadowColor: fg.withValues(alpha: 0.45),
      color: disabled ? bg.withValues(alpha: 0.45) : bg,
      shape: const CircleBorder(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: fg.withValues(alpha: 0.32),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: disabled ? fg.withValues(alpha: 0.38) : fg,
          ),
        ),
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
              accent: AppIconAccent.create,
            ),
            const SizedBox(width: AppUiTokens.toolbarFabGap),
          ],
          PageToolbarFab(
            tooltip: helpTooltip,
            icon: Icons.help_outline_rounded,
            onPressed: onHelp,
            primary: false,
            accent: AppIconAccent.help,
          ),
        ],
      ),
    );
  }
}
