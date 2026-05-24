using System.IO;
using Microsoft.Win32;

namespace AudioStegano.Desktop.Services;

/// <summary>Per-user (HKCU) Open-with registration for WAV/MP3/MP4 — no admin required.</summary>
public static class WindowsFileAssociationService
{
    public const string ProgId = "Karavi.AudioStegano.AudioFile";
    private static readonly string[] Extensions = [".wav", ".mp3", ".mp4"];

    public static bool IsRegistered(string exePath)
    {
        try
        {
            using var cmd = Registry.CurrentUser.OpenSubKey($@"Software\Classes\{ProgId}\shell\open\command");
            var value = cmd?.GetValue(null) as string;
            return value is not null &&
                   value.Contains(exePath, StringComparison.OrdinalIgnoreCase);
        }
        catch
        {
            return false;
        }
    }

    public static void Register(string exePath, string displayName)
    {
        if (!OperatingSystem.IsWindows())
            return;

        exePath = Path.GetFullPath(exePath);
        var quotedExe = $"\"{exePath}\"";

        using (var prog = Registry.CurrentUser.CreateSubKey($@"Software\Classes\{ProgId}"))
        {
            prog.SetValue("", displayName);
            using var icon = prog.CreateSubKey("DefaultIcon");
            icon?.SetValue("", $"{quotedExe},0");
            using var shell = prog.CreateSubKey(@"shell\open\command");
            shell?.SetValue("", $"{quotedExe} \"%1\"");
        }

        var exeFileName = Path.GetFileName(exePath);
        using (var app = Registry.CurrentUser.CreateSubKey($@"Software\Classes\Applications\{exeFileName}"))
        {
            app.SetValue("FriendlyAppName", displayName);
            using var appIcon = app.CreateSubKey("DefaultIcon");
            appIcon?.SetValue("", $"{quotedExe},0");
            using var appCmd = app.CreateSubKey(@"shell\open\command");
            appCmd?.SetValue("", $"{quotedExe} \"%1\"");
        }

        foreach (var ext in Extensions)
        {
            using var openWith = Registry.CurrentUser.CreateSubKey($@"Software\Classes\{ext}\OpenWithProgids");
            openWith?.SetValue(ProgId, string.Empty, RegistryValueKind.None);
        }

        using (var clients = Registry.CurrentUser.CreateSubKey(@"Software\Clients\Media\AudioStegano"))
        {
            clients.SetValue("", displayName);
            using var caps = clients.CreateSubKey("Capabilities");
            caps?.SetValue("ApplicationName", displayName);
            caps?.SetValue("ApplicationDescription", displayName);
            foreach (var ext in Extensions)
            {
                var noDot = ext.TrimStart('.');
                caps?.SetValue(ext, $"{ProgId}");
            }
        }

        using var regApps = Registry.CurrentUser.CreateSubKey(@"Software\RegisteredApplications");
        regApps?.SetValue("AudioStegano.Desktop", @"Software\Clients\Media\AudioStegano");
    }

    public static void Unregister()
    {
        if (!OperatingSystem.IsWindows())
            return;

        try
        {
            Registry.CurrentUser.DeleteSubKeyTree($@"Software\Classes\{ProgId}", false);
        }
        catch { /* ignore */ }

        foreach (var ext in Extensions)
        {
            try
            {
                using var openWith = Registry.CurrentUser.OpenSubKey($@"Software\Classes\{ext}\OpenWithProgids", true);
                openWith?.DeleteValue(ProgId, false);
            }
            catch { /* ignore */ }
        }

        try
        {
            Registry.CurrentUser.DeleteSubKeyTree(@"Software\Clients\Media\AudioStegano", false);
        }
        catch { /* ignore */ }

        try
        {
            using var regApps = Registry.CurrentUser.OpenSubKey(@"Software\RegisteredApplications", true);
            regApps?.DeleteValue("AudioStegano.Desktop", false);
        }
        catch { /* ignore */ }
    }
}
