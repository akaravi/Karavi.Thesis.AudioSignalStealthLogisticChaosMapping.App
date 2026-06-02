using System.IO;
using System.Text.Json;
using System.Text.Json.Nodes;
using AudioStegano.Core.Stego;

namespace AudioStegano.Desktop;

public enum AppLanguage { Fa, En, Ar, Fr }

public enum AppThemeMode { System, Light, Dark }

public sealed class AppSettings
{
    public AppThemeMode ThemeMode { get; set; } = AppThemeMode.System;
    public AppLanguage Language { get; set; } = AppLanguage.Fa;
    public double R { get; set; } = WatermarkDefaults.R;
    public double X0 { get; set; } = WatermarkDefaults.X0;
    public string AccentColor { get; set; } = "#00B4B7";

    /// <summary>When true, embed/extract use <see cref="AppConfig.DefaultFixedMessageBitLength"/>.</summary>
    public bool DefaultFixedMessageBitLimit { get; set; } = true;

    /// <summary>False until the user picks a language on first run (Flutter parity).</summary>
    public bool LocaleConfigured { get; set; }

    /// <summary>False until the one-time usage guide is dismissed.</summary>
    public bool UsageGuideSeen { get; set; }

    /// <summary>Register WAV/MP3/MP4 in Explorer “Open with” (HKCU, per-user).</summary>
    public bool RegisterWindowsFileAssociations { get; set; }

    /// <summary>True after the one-time Open-with prompt was shown (yes or no).</summary>
    public bool WindowsOpenWithOfferSeen { get; set; }

    /// <summary><c>xor_only</c> or <c>ae_xor</c> steganography path.</summary>
    public StegoEmbedMode StegoEmbedMode { get; set; } = StegoEmbedMode.XorOnly;
}

public static class AppState
{
    /// <summary>WAV/MP3 path from Explorer “Open with” or command line (consumed by MainWindow).</summary>
    public static string? PendingOpenAudioPath { get; set; }

    private static readonly string SettingsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "AudioStegano.Desktop",
        "settings.json");

    public static AppSettings Settings { get; private set; } = new();

    public static EmbedMessage Embed => Settings.StegoEmbedMode == StegoEmbedMode.AeXor
        ? new EmbedMessage(Settings.R, Settings.X0, StegoEmbedMode.AeXor, TrainedAutoencoder.Instance)
        : new EmbedMessage(Settings.R, Settings.X0);

    public static ExtractMessage Extract => Settings.StegoEmbedMode == StegoEmbedMode.AeXor
        ? new ExtractMessage(Settings.R, Settings.X0, StegoEmbedMode.AeXor, TrainedAutoencoder.Instance)
        : new ExtractMessage(Settings.R, Settings.X0);

    /// <summary>سازگاری با کد قبلی.</summary>
    public static AudioWatermarking Watermarking =>
        Settings.StegoEmbedMode == StegoEmbedMode.AeXor
            ? new AudioWatermarking(Settings.R, Settings.X0, StegoEmbedMode.AeXor, TrainedAutoencoder.Instance)
            : new AudioWatermarking(Settings.R, Settings.X0);

    public static void Load()
    {
        AppConfig.Load();
        Settings = new AppSettings
        {
            R = AppConfig.Current.LogisticR,
            X0 = AppConfig.Current.LogisticX0,
            StegoEmbedMode = StegoEmbedModeParser.FromConfig(AppConfig.Current.DefaultStegoEmbedMode),
        };
        MergeSettingsFromFile(SettingsPath);
    }

    private static void MergeSettingsFromFile(string path)
    {
        if (!File.Exists(path)) return;
        try
        {
            var json = File.ReadAllText(path);
            var loaded = JsonSerializer.Deserialize<AppSettings>(json);
            if (loaded is null) return;
            var merged = Merge(Settings, loaded);
            if (!JsonNode.Parse(json)!.AsObject().ContainsKey(
                    nameof(AppSettings.DefaultFixedMessageBitLimit)))
                merged.DefaultFixedMessageBitLimit = true;
            Settings = merged;
        }
        catch
        {
            // Keep current values when a file is invalid.
        }
    }

    private static AppSettings Merge(AppSettings target, AppSettings source) =>
        new()
        {
            ThemeMode = source.ThemeMode,
            Language = source.Language,
            R = source.R,
            X0 = source.X0,
            AccentColor = source.AccentColor,
            DefaultFixedMessageBitLimit = source.DefaultFixedMessageBitLimit,
            LocaleConfigured = source.LocaleConfigured,
            UsageGuideSeen = source.UsageGuideSeen,
            RegisterWindowsFileAssociations = source.RegisterWindowsFileAssociations,
            WindowsOpenWithOfferSeen = source.WindowsOpenWithOfferSeen,
        };

    public static void Save()
    {
        var dir = Path.GetDirectoryName(SettingsPath)!;
        Directory.CreateDirectory(dir);
        var json = JsonSerializer.Serialize(Settings, new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(SettingsPath, json);
    }

    public static void ResetToDefaults()
    {
        var keepLocale = Settings.LocaleConfigured;
        var keepGuide = Settings.UsageGuideSeen;
        Settings = new AppSettings
        {
            R = AppConfig.Current.LogisticR,
            X0 = AppConfig.Current.LogisticX0,
            LocaleConfigured = keepLocale,
            UsageGuideSeen = keepGuide,
        };
    }

    public static void CompleteLocaleOnboarding() => Settings.LocaleConfigured = true;

    public static void CompleteUsageGuideOnboarding() => Settings.UsageGuideSeen = true;
}
