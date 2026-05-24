namespace AudioStegano.Desktop.Localization;

/// <summary>User-facing audio load/decode errors (Flutter <c>audio_load_errors.dart</c> parity).</summary>
public static class AudioLoadErrors
{
    public static string Format(AppStrings strings, object error)
    {
        var text = error.ToString() ?? string.Empty;
        if (text.Contains("MP4 decode failed", StringComparison.Ordinal))
            return strings.ErrorMp4Decode;

        if (text.Contains("MP3 decode failed", StringComparison.Ordinal) ||
            text.Contains("Media decode failed", StringComparison.Ordinal))
            return strings.ErrorMp3Decode;

        return text;
    }
}
