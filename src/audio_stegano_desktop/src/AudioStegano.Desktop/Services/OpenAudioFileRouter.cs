using System.IO;
using System.Windows;

namespace AudioStegano.Desktop.Services;

/// <summary>Routes an external audio path to the Extract tab (Flutter Android open-with parity).</summary>
public static class OpenAudioFileRouter
{
    public static void Route(string? path)
    {
        if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
            return;

        SessionLog.Write($"Open with: {path}");
        AppState.PendingOpenAudioPath = path;

        if (Application.Current?.Dispatcher is null)
            return;

        Application.Current.Dispatcher.BeginInvoke(() =>
        {
            if (Application.Current.MainWindow is MainWindow main)
                main.OpenPendingAudioFile();
        });
    }
}
