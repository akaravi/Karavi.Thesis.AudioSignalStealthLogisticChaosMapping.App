using System.IO;
using System.Text.Json;
using AudioSteg.Core.Stego;

namespace AudioSteg.Desktop;

public enum AppLanguage { Fa, En }

public enum AppThemeMode { System, Light, Dark }

public sealed class AppSettings
{
    public AppThemeMode ThemeMode { get; set; } = AppThemeMode.System;
    public AppLanguage Language { get; set; } = AppLanguage.Fa;
    public double R { get; set; } = WatermarkDefaults.R;
    public double X0 { get; set; } = WatermarkDefaults.X0;
    public string AccentColor { get; set; } = "#6750A4";
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

    public static void Load()
    {
        try
        {
            if (!File.Exists(SettingsPath)) return;
            var json = File.ReadAllText(SettingsPath);
            var loaded = JsonSerializer.Deserialize<AppSettings>(json);
            if (loaded is not null) Settings = loaded;
        }
        catch
        {
            Settings = new AppSettings();
        }
    }

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
    }
}
