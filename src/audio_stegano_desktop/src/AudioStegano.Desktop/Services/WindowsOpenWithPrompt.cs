using System.Windows;
using AudioStegano.Desktop.Localization;

namespace AudioStegano.Desktop.Services;

/// <summary>One-time offer to register Explorer Open with (after usage guide or first main window).</summary>
public static class WindowsOpenWithPrompt
{
    public static void OfferIfNeeded()
    {
        if (!OperatingSystem.IsWindows())
            return;

        if (AppState.Settings.RegisterWindowsFileAssociations ||
            AppState.Settings.WindowsOpenWithOfferSeen)
            return;

        AppState.Settings.WindowsOpenWithOfferSeen = true;
        AppState.Save();

        var s = ThemeManager.Strings;
        var result = MessageBox.Show(
            s.WindowsOpenWithFirstRunPrompt,
            s.AppTitle,
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);
        if (result != MessageBoxResult.Yes)
            return;

        var exe = Environment.ProcessPath;
        if (string.IsNullOrEmpty(exe))
            return;

        AppState.Settings.RegisterWindowsFileAssociations = true;
        AppState.Save();
        WindowsFileAssociationService.Register(exe, s.AppTitle);
    }
}
