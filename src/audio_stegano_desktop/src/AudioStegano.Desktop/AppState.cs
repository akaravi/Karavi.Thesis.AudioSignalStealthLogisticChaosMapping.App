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

}



public static class AppState

{

    private static readonly string SettingsPath = Path.Combine(

        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),

        "AudioStegano.Desktop",

        "settings.json");



    public static AppSettings Settings { get; private set; } = new();



    public static AudioWatermarking Watermarking =>

        new(Settings.R, Settings.X0);



    public static void Load()

    {

        AppConfig.Load();

        Settings = new AppSettings

        {

            R = AppConfig.Current.LogisticR,

            X0 = AppConfig.Current.LogisticX0,

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

            R = AppConfig.Current.LogisticR,

            X0 = AppConfig.Current.LogisticX0,

        };

    }

}

