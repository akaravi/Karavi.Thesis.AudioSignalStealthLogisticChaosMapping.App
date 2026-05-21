using System.IO;
using System.Text.Json;

namespace AudioSteg.Desktop;

/// <summary>
/// Deploy-time flags from <c>appsettings.json</c> beside the executable (not user settings UI).
/// </summary>
public sealed class AppConfig
{
    /// <summary>When false, hides the upload-file button on the embed (steganography) tab.</summary>
    public bool ShowEmbedLoadFileButton { get; set; } = false;

    /// <summary>When true, shows recovery message-length dialog after embed.</summary>
    public bool ShowEmbedRecoveryDialog { get; set; } = true;

    public static AppConfig Current { get; private set; } = new();

    private static string AppSettingsFilePath =>
        Path.Combine(AppContext.BaseDirectory, "appsettings.json");

    public static void Load()
    {
        Current = new AppConfig();
        if (!File.Exists(AppSettingsFilePath)) return;
        try
        {
            var json = File.ReadAllText(AppSettingsFilePath);
            var loaded = JsonSerializer.Deserialize<AppConfig>(json);
            if (loaded is not null)
                Current = loaded;
        }
        catch
        {
            // Keep defaults when the file is invalid.
        }
    }
}
