/// Audio file opened from «Open with» (Android ACTION_VIEW or desktop CLI args).
class OpenedAudioFile {
  const OpenedAudioFile({required this.path, required this.displayName});

  final String path;
  final String displayName;
}
