using System.Windows;
using System.Windows.Media;
using AudioStegano.Desktop.Localization;

namespace AudioStegano.Desktop;

public static class ThemeManager
{
    public const string SoftPurpleAccent = "#7A68A8";

    public static void Apply(ResourceDictionary resources)
    {
        var s = AppState.Settings;
        var isDark = s.ThemeMode switch
        {
            AppThemeMode.Dark => true,
            AppThemeMode.Light => false,
            _ => false, // system retired → light purple
        };

        resources.MergedDictionaries.Clear();
        resources.MergedDictionaries.Add(LoadDict("Themes/SharedStyles.xaml"));
        resources.MergedDictionaries.Add(LoadDict(isDark ? "Themes/DarkTheme.xaml" : "Themes/LightTheme.xaml"));

        // Fixed soft-purple accent — no user color picker.
        s.AccentColor = SoftPurpleAccent;
        var accent = (Color)ColorConverter.ConvertFromString(SoftPurpleAccent)!;
        var primary = isDark ? SoftenForDarkPrimary(accent) : accent;
        var primaryContainer = SoftPrimaryContainer(accent, isDark);
        var secondaryContainer = SoftSecondaryContainer(accent, isDark);
        var onPrimary = isDark ? Color.FromRgb(0x2A, 0x1F, 0x40) : Colors.White;
        var onPrimaryContainer = isDark
            ? Color.FromRgb(0xE9, 0xDE, 0xF8)
            : Color.FromRgb(0x3D, 0x2F, 0x5C);
        var chartStego = SoftChartStego(accent, isDark);

        resources["AccentBrush"] = new SolidColorBrush(primary);
        resources["AccentForegroundBrush"] = new SolidColorBrush(onPrimary);
        resources["PrimaryBrush"] = new SolidColorBrush(primary);
        resources["OnPrimaryBrush"] = new SolidColorBrush(onPrimary);
        resources["PrimaryContainerBrush"] = new SolidColorBrush(primaryContainer);
        resources["OnPrimaryContainerBrush"] = new SolidColorBrush(onPrimaryContainer);
        resources["SecondaryContainerBrush"] = new SolidColorBrush(secondaryContainer);
        resources["NavIndicatorBrush"] = new SolidColorBrush(primaryContainer);
        resources["ChartCoverBrush"] = new SolidColorBrush(primary);
        resources["ChartStegoBrush"] = new SolidColorBrush(chartStego);
    }

    public static void Apply(Window window)
    {
        Apply(window.Resources);
        var s = AppState.Settings;
        window.FlowDirection = s.Language is AppLanguage.Fa or AppLanguage.Ar
            ? FlowDirection.RightToLeft
            : FlowDirection.LeftToRight;

        window.FontFamily = s.Language is AppLanguage.Fa or AppLanguage.Ar
            ? new FontFamily("Segoe UI, Tahoma")
            : new FontFamily("Segoe UI");
    }

    public static AppStrings Strings => new(AppState.Settings.Language);

    private static Color SoftenForDarkPrimary(Color accent) =>
        Mix(accent, Color.FromRgb(0xE8, 0xE0, 0xF0), 0.42);

    private static Color SoftPrimaryContainer(Color accent, bool dark) =>
        dark
            ? Mix(accent, Color.FromRgb(0x16, 0x13, 0x1C), 0.58)
            : Mix(accent, Colors.White, 0.78);

    private static Color SoftSecondaryContainer(Color accent, bool dark) =>
        dark
            ? Mix(accent, Color.FromRgb(0x16, 0x13, 0x1C), 0.70)
            : Mix(accent, Colors.White, 0.86);

    private static Color SoftChartStego(Color accent, bool dark) =>
        dark
            ? Mix(accent, Color.FromRgb(0xE8, 0xE0, 0xF0), 0.35)
            : Mix(accent, Color.FromRgb(0x3D, 0x2F, 0x5C), 0.25);

    private static Color Mix(Color a, Color b, double t)
    {
        t = Math.Clamp(t, 0, 1);
        return Color.FromArgb(
            255,
            (byte)(a.R + (b.R - a.R) * t),
            (byte)(a.G + (b.G - a.G) * t),
            (byte)(a.B + (b.B - a.B) * t));
    }

    private static ResourceDictionary LoadDict(string path) =>
        new() { Source = new Uri(path, UriKind.Relative) };
}
