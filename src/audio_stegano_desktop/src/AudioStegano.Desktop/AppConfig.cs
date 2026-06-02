using System.IO;
using System.Text.Json;

namespace AudioStegano.Desktop;

/// <summary>
/// Deploy-time flags from <c>appsettings.json</c> beside the executable (not user settings UI).
/// </summary>
public sealed class AppConfig
{
    /// <summary>When false, hides the upload-file button on the embed (steganography) tab.</summary>
    public bool ShowEmbedLoadFileButton { get; set; } = false;

    /// <summary>When true, shows recovery message-length dialog after embed.</summary>
    public bool ShowEmbedRecoveryDialog { get; set; } = true;

    /// <summary>Fixed msg_len when default message bit limit is enabled (2^18 = 262144).</summary>
    public int DefaultFixedMessageBitLength { get; set; } = 262144;

    /// <summary>Default logistic map r for new sessions / reset.</summary>
    public double LogisticR { get; set; } = 3.99;

    /// <summary>Default logistic map x0 for new sessions / reset.</summary>
    public double LogisticX0 { get; set; } = 0.45;

    /// <summary><c>xor_only</c> or <c>ae_xor</c> — <c>train/embed_message.m</c> embed_mode.</summary>
    public string DefaultStegoEmbedMode { get; set; } = "xor_only";

    public static AppConfig Current { get; private set; } = new();

    /// <summary>Embed tab: on Windows desktop, file load stays available even when deploy flag is false (mobile-oriented default).</summary>
    public static bool ShowEmbedLoadFileForUi =>
        Current.ShowEmbedLoadFileButton || OperatingSystem.IsWindows();

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
