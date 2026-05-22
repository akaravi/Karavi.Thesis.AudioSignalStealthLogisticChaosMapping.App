import '../../app/app_strings.dart';

/// User-facing message when [AudioInputLoader] or decoders fail.
String audioLoadErrorMessage(AppStrings strings, Object error) {
  final text = error.toString();
  if (text.contains('MP4 decode failed')) {
    return strings.errorMp4Decode;
  }
  if (text.contains('MP3 decode failed') ||
      text.contains('Media decode failed')) {
    return strings.errorMp3Decode;
  }
  return text;
}
