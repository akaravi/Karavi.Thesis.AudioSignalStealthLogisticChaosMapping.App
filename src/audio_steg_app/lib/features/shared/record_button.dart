import 'package:flutter/material.dart';

import 'circle_action_button.dart';

/// Animated recording button with pulse halo while active.
class RecordButton extends StatelessWidget {
  final bool isActive;
  final bool enabled;
  final VoidCallback onPressed;
  final IconData iconIdle;
  final IconData iconActive;
  final String labelIdle;
  final String labelActive;

  const RecordButton({
    super.key,
    required this.isActive,
    this.enabled = true,
    required this.onPressed,
    this.iconIdle = Icons.mic_rounded,
    this.iconActive = Icons.stop_rounded,
    required this.labelIdle,
    required this.labelActive,
  });

  @override
  Widget build(BuildContext context) {
    return CircleActionButton(
      enabled: enabled,
      onPressed: onPressed,
      icon: isActive ? iconActive : iconIdle,
      label: isActive ? labelActive : labelIdle,
      accent: isActive ? CircleActionAccent.error : CircleActionAccent.primary,
      showPulse: isActive,
    );
  }
}
