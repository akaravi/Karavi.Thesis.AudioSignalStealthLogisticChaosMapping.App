import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../../core/audio/audio_input_loader.dart';
import '../../core/platform/platform.dart';

/// Desktop drag-and-drop for WAV/MP3/MP4 (WPF [AudioFileDropHelper] parity).
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

  static bool _isSupportedPath(String path) {
    final ext = p.extension(path).toLowerCase();
    return AudioInputLoader.audioPickerExtensions.contains(
      ext.replaceFirst('.', ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktopNative) {
      return child;
    }
    return DropTarget(
      onDragEntered: (_) {},
      onDragExited: (_) {},
      onDragDone: (details) {
        if (!enabled || details.files.isEmpty) return;
        final file = details.files.first;
        final path = file.path;
        if (path.isEmpty || !_isSupportedPath(path)) return;
        onFilePath(path);
      },
      child: child,
    );
  }
}
