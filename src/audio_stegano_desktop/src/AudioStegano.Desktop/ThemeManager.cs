using System.Windows;
using System.Windows.Media;
using AudioStegano.Desktop.Localization;

namespace AudioStegano.Desktop;

public static class ThemeManager
{
    public static void Apply(ResourceDictionary resources)
    {
        var s = AppState.Settings;
        var isDark = s.ThemeMode switch
        {
            AppThemeMode.Dark => true,
            AppThemeMode.Light => false,
            _ => IsSystemDark(),
        };

        resources.MergedDictionaries.Clear();
        resources.MergedDictionaries.Add(LoadDict("Themes/SharedStyles.xaml"));
        resources.MergedDictionaries.Add(LoadDict(isDark ? "Themes/DarkTheme.xaml" : "Themes/LightTheme.xaml"));

        var accent = (Color)ColorConverter.ConvertFromString(s.AccentColor)!;
        resources["AccentBrush"] = new SolidColorBrush(accent);
        resources["AccentForegroundBrush"] = new SolidColorBrush(Colors.White);
        resources["PrimaryBrush"] = new SolidColorBrush(accent);
        resources["ChartCoverBrush"] = new SolidColorBrush(accent);
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

    private static ResourceDictionary LoadDict(string path) =>
        new() { Source = new Uri(path, UriKind.Relative) };

    private static bool IsSystemDark()
    {
        try
        {
            using var key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(
                @"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize");
            var value = key?.GetValue("AppsUseLightTheme");
            return value is int i && i == 0;
        }
        catch
        {
            return false;
        }
    }
}
