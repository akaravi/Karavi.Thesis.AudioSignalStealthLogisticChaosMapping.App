import 'package:flutter/material.dart';

/// Visual accent for [CircleActionButton] gradients (theme-aware).
enum CircleActionAccent { primary, secondary, error }

/// Large circular action with gradient, glow, and optional pulse ring.
class CircleActionButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final CircleActionAccent accent;
  final bool showPulse;

  const CircleActionButton({
    super.key,
    required this.enabled,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.accent = CircleActionAccent.primary,
    this.showPulse = false,
  });

  @override
  State<CircleActionButton> createState() => _CircleActionButtonState();
}

class _CircleActionButtonState extends State<CircleActionButton>
    with SingleTickerProviderStateMixin {
  static const double _stackSize = 118;
  static const double _circleSize = 76;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(CircleActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.showPulse && widget.enabled) {
      if (!_pulseCtrl.isAnimating) {
        _pulseCtrl.repeat(reverse: true);
      }
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  (Color base, Color onIcon) _resolveColors(ColorScheme scheme) {
    switch (widget.accent) {
      case CircleActionAccent.secondary:
        return (scheme.tertiary, scheme.onTertiary);
      case CircleActionAccent.error:
        return (scheme.error, scheme.onError);
      case CircleActionAccent.primary:
        return (scheme.primary, scheme.onPrimary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final (base, onIcon) = _resolveColors(scheme);
    final disabled = !widget.enabled;
    final baseColor = disabled
        ? scheme.onSurface.withValues(alpha: 0.28)
        : base;
    final iconColor = disabled
        ? scheme.onSurface.withValues(alpha: 0.45)
        : onIcon;
    final labelStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: disabled ? scheme.onSurface.withValues(alpha: 0.38) : null,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _stackSize,
          height: _stackSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.showPulse && widget.enabled)
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) {
                    final t = _pulseCtrl.value;
                    return Container(
                      width: 92 + 18 * t,
                      height: 92 + 18 * t,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: baseColor.withValues(alpha: 0.12 + 0.18 * t),
                      ),
                    );
                  },
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(
                      alpha: disabled ? 0.25 : 0.55,
                    ),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.enabled ? widget.onPressed : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: _circleSize,
                      height: _circleSize,
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: disabled
                              ? [
                                  scheme.surfaceContainerHigh,
                                  scheme.surfaceContainerHighest,
                                ]
                              : [
                                  baseColor,
                                  Color.lerp(baseColor, scheme.surface, 0.22)!,
                                ],
                        ),
                        boxShadow: disabled
                            ? null
                            : [
                                BoxShadow(
                                  color: baseColor.withValues(alpha: 0.42),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: scheme.shadow.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Icon(widget.icon, size: 34, color: iconColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 124,
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
      ],
    );
  }
}

/// Side-by-side record / load actions with a soft panel and «or» divider.
class AudioSourceActionsPanel extends StatelessWidget {
  final String orLabel;
  final Widget loadAction;
  final Widget recordAction;

  const AudioSourceActionsPanel({
    super.key,
    required this.orLabel,
    required this.loadAction,
    required this.recordAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.35),
            scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Center(child: loadAction)),
          Padding(
            padding: const EdgeInsets.only(top: 44),
            child: Column(
              children: [
                Container(
                  width: 1,
                  height: 36,
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    orLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          Expanded(child: Center(child: recordAction)),
        ],
      ),
    );
  }
}
