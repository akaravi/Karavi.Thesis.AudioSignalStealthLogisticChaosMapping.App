using System.IO;
using System.Text.Json;
using AudioSteg.Core.Stego;

namespace AudioSteg.Desktop;

public enum AppLanguage { Fa, En, Ar, Fr }

public enum AppThemeMode { System, Light, Dark }

public sealed class AppSettings
{
    public AppThemeMode ThemeMode { get; set; } = AppThemeMode.System;
    public AppLanguage Language { get; set; } = AppLanguage.Fa;
    public double R { get; set; } = WatermarkDefaults.R;
    public double X0 { get; set; } = WatermarkDefaults.X0;
    public string AccentColor { get; set; } = "#00B4B7";
}

public static class AppState
{
    private static readonly string SettingsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "AudioSteg.Desktop",
        "settings.json");

    public static AppSettings Settings { get; private set; } = new();

    public static AudioWatermarking Watermarking =>
        new(Settings.R, Settings.X0);

    private static string AppSettingsFilePath =>
        Path.Combine(AppContext.BaseDirectory, "appsettings.json");

    public static void Load()
    {
        AppConfig.Load();
        Settings = new AppSettings();
        MergeSettingsFromFile(AppSettingsFilePath);
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
            Settings = Merge(Settings, loaded);
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
        Settings = new AppSettings
        {
            R = WatermarkDefaults.R,
            X0 = WatermarkDefaults.X0,
        };
        MergeSettingsFromFile(AppSettingsFilePath);
    }
}
