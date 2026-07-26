using System.IO;
using System.Windows;
using AudioStegano.Core.Audio;
using AudioStegano.Desktop.Services;

namespace AudioStegano.Desktop;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        var path = ResolveAudioPathFromArgs(e.Args);
        if (!SingleInstanceService.TryBecomePrimary())
        {
            if (path is not null)
                SingleInstanceService.SendPathToPrimary(path);
            Shutdown();
            return;
        }

        AppState.Load();
        SessionLog.Init();
        SessionLog.Write("App starting");
        HookGlobalExceptionLogging();
        ThemeManager.Apply(Resources);
        ApplyFileAssociationsIfEnabled();

        AppState.PendingOpenAudioPath = path;
        SingleInstanceService.StartServer(OpenAudioFileRouter.Route);

        new BootstrapWindow().Show();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        SingleInstanceService.Stop();
        AudioInputLoader.ShutdownMediaFoundation();
        base.OnExit(e);
    }

    private static void ApplyFileAssociationsIfEnabled()
    {
        if (!OperatingSystem.IsWindows() || !AppState.Settings.RegisterWindowsFileAssociations)
            return;

        var exe = Environment.ProcessPath;
        if (string.IsNullOrEmpty(exe))
            return;

        if (!WindowsFileAssociationService.IsRegistered(exe))
        {
            try
            {
                WindowsFileAssociationService.Register(exe, ThemeManager.Strings.AppTitle);
            }
            catch
            {
                // Non-fatal: Open-with registration must not block app startup.
            }
        }
    }

    internal static string? ResolveAudioPathFromArgs(string[] args)
    {
        foreach (var arg in args)
        {
            if (string.IsNullOrWhiteSpace(arg) || arg.StartsWith('-'))
                continue;
            var path = arg.Trim('"');
            if (!IsSupportedAudioExtension(path))
                continue;
            if (File.Exists(path))
                return path;
        }

        return null;
    }

    internal static bool IsSupportedAudioExtension(string path)
    {
        var ext = Path.GetExtension(path);
        return ext.Equals(".wav", StringComparison.OrdinalIgnoreCase) ||
               ext.Equals(".mp3", StringComparison.OrdinalIgnoreCase) ||
               ext.Equals(".mp4", StringComparison.OrdinalIgnoreCase);
    }

    private void HookGlobalExceptionLogging()
    {
        AppDomain.CurrentDomain.UnhandledException += (_, args) =>
        {
            var ex = args.ExceptionObject as Exception;
            SessionLog.Write("UnhandledException", ex);
        };

        DispatcherUnhandledException += (_, args) =>
            SessionLog.Write("DispatcherUnhandledException", args.Exception);

        TaskScheduler.UnobservedTaskException += (_, args) =>
        {
            SessionLog.Write("UnobservedTaskException", args.Exception);
            args.SetObserved();
        };
    }
}
