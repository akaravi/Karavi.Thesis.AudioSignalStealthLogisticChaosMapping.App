using System.Windows;
using System.Windows.Media;
using AudioSteg.Desktop.Localization;

namespace AudioSteg.Desktop;

public static class ThemeManager
{
    public static void Apply(Window window)
    {
        var s = AppState.Settings;
        var isDark = s.ThemeMode switch
        {
            AppThemeMode.Dark => true,
            AppThemeMode.Light => false,
            _ => IsSystemDark(),
        };

        window.Resources.MergedDictionaries.Clear();
        window.Resources.MergedDictionaries.Add(
            new ResourceDictionary
            {
                Source = new Uri(isDark
                    ? "Themes/DarkTheme.xaml"
                    : "Themes/LightTheme.xaml", UriKind.Relative),
            });

        var accent = (Color)ColorConverter.ConvertFromString(s.AccentColor)!;
        window.Resources["AccentBrush"] = new SolidColorBrush(accent);
        window.Resources["AccentForegroundBrush"] = new SolidColorBrush(Colors.White);

        window.FlowDirection = s.Language == AppLanguage.Fa
            ? FlowDirection.RightToLeft
            : FlowDirection.LeftToRight;

        window.FontFamily = s.Language == AppLanguage.Fa
            ? new FontFamily("Segoe UI, Tahoma")
            : new FontFamily("Segoe UI");
    }

    public static AppStrings Strings => new(AppState.Settings.Language);

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
