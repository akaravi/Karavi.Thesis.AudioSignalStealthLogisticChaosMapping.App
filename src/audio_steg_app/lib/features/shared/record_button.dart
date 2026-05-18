import 'package:flutter/material.dart';

/// Animated recording / listening button with a pulsing halo.
class RecordButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onPressed;
  final IconData iconIdle;
  final IconData iconActive;
  final String labelIdle;
  final String labelActive;
  final Color? color;

  const RecordButton({
    super.key,
    required this.isActive,
    required this.onPressed,
    this.iconIdle = Icons.mic_outlined,
    this.iconActive = Icons.stop_rounded,
    required this.labelIdle,
    required this.labelActive,
    this.color,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final activeColor = Theme.of(context).colorScheme.error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 130,
          width: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isActive)
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor.withValues(alpha: 0.15 + 0.20 * _ctrl.value),
                      ),
                      width: 110 + 20 * _ctrl.value,
                      height: 110 + 20 * _ctrl.value,
                    );
                  },
                ),
              GestureDetector(
                onTap: widget.onPressed,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.isActive
                          ? [activeColor, activeColor.withValues(alpha: 0.7)]
                          : [color, color.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isActive ? activeColor : color).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isActive ? widget.iconActive : widget.iconIdle,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isActive ? widget.labelActive : widget.labelIdle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}
