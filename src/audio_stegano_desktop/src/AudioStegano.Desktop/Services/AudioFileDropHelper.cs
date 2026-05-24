using System.IO;
using System.Windows;
namespace AudioStegano.Desktop.Services;

/// <summary>Drag-and-drop of WAV/MP3/MP4 onto a surface (desktop Flutter parity).</summary>
public static class AudioFileDropHelper
{
    public static void Enable(UIElement control, Func<string, Task> onFileDropped)
    {
        control.AllowDrop = true;
        control.DragOver += (_, e) =>
        {
            if (!e.Data.GetDataPresent(DataFormats.FileDrop))
                return;
            e.Effects = DragDropEffects.Copy;
            e.Handled = true;
        };
        control.Drop += async (_, e) =>
        {
            if (e.Data.GetData(DataFormats.FileDrop) is not string[] paths || paths.Length == 0)
                return;
            e.Handled = true;
            var path = paths[0];
            if (!App.IsSupportedAudioExtension(path) || !File.Exists(path))
                return;
            await onFileDropped(path);
        };
    }
}
