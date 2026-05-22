/// Audio file opened from Android «Open with» (ACTION_VIEW).
class OpenedAudioFile {
  const OpenedAudioFile({required this.path, required this.displayName});

  final String path;
  final String displayName;
}
