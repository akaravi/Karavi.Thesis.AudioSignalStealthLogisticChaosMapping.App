import 'package:flutter/widgets.dart';

/// Drag-and-drop wrapper (no-op on web / mobile).
class AudioFileDropSurface extends StatelessWidget {
  const AudioFileDropSurface({
    super.key,
    required this.child,
    required this.enabled,
    required this.onFilePath,
  });

  final Widget child;
  final bool enabled;
  final ValueChanged<String> onFilePath;

  @override
  Widget build(BuildContext context) => child;
}
