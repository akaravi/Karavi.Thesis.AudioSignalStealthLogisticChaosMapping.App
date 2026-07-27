import 'package:flutter/material.dart';

import '../../app/app_icon_accents.dart';

/// Colored Material icon using [AppIconAccent] (explicit color wins over IconTheme).
class AccentIcon extends StatelessWidget {
  const AccentIcon(
    this.icon, {
    super.key,
    required this.accent,
    this.size,
    this.selected = true,
  });

  final IconData icon;
  final AppIconAccent accent;
  final double? size;

  /// When false, blends accent toward muted for unselected nav states.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final fg = AppIconAccents.foreground(accent, brightness);
    final color = selected
        ? fg
        : Color.lerp(fg, scheme.onSurfaceVariant, 0.42)!;
    return Icon(icon, size: size, color: color);
  }
}

/// Soft glow tile for hero / section icons (audio pick, success, etc.).
class AccentGlowIcon extends StatelessWidget {
  const AccentGlowIcon(
    this.icon, {
    super.key,
    required this.accent,
    this.size = 28,
    this.tileSize = 56,
  });

  final IconData icon;
  final AppIconAccent accent;
  final double size;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = AppIconAccents.foreground(accent, brightness);
    final container = AppIconAccents.container(accent, brightness);
    return Center(
      child: Container(
        width: tileSize,
        height: tileSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              fg,
              Color.lerp(fg, container, 0.35)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: fg.withValues(alpha: 0.38),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, size: size, color: AppIconAccents.onFill(brightness)),
      ),
    );
  }
}

/// Icon-only action with semantic fill/tonal + soft glow.
class AccentActionIconButton extends StatelessWidget {
  const AccentActionIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.accent,
    required this.onPressed,
    this.filled = false,
    this.busyChild,
  });

  final String tooltip;
  final IconData icon;
  final AppIconAccent accent;
  final VoidCallback? onPressed;
  final bool filled;
  final Widget? busyChild;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = AppIconAccents.foreground(accent, brightness);
    final disabled = onPressed == null && busyChild == null;
    final child = busyChild ??
        Icon(
          icon,
          color: filled
              ? AppIconAccents.onFill(brightness)
              : (disabled ? fg.withValues(alpha: 0.38) : fg),
        );

    final button = filled
        ? IconButton.filled(
            onPressed: onPressed,
            style: IconButton.styleFrom(
              backgroundColor: disabled
                  ? fg.withValues(alpha: 0.28)
                  : fg,
              foregroundColor: AppIconAccents.onFill(brightness),
              shadowColor: fg.withValues(alpha: 0.45),
              elevation: disabled ? 0 : 3,
            ),
            icon: child,
          )
        : IconButton.filledTonal(
            onPressed: onPressed,
            style: IconButton.styleFrom(
              backgroundColor: AppIconAccents.container(accent, brightness),
              foregroundColor: fg,
              shadowColor: fg.withValues(alpha: 0.28),
              elevation: disabled ? 0 : 1.5,
            ),
            icon: child,
          );

    return Tooltip(message: tooltip, child: button);
  }
}
