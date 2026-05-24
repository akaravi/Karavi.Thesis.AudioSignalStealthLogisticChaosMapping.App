using System.Diagnostics;
using System.IO;

namespace AudioStegano.Desktop.Services;

/// <summary>Append-only session log (Flutter <c>session_log.dart</c> parity for diagnostics).</summary>
public static class SessionLog
{
    private static readonly object Gate = new();
    private static string? _path;

    public static void Init()
    {
        try
        {
            var dir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "AudioStegano.Desktop",
                "logs");
            Directory.CreateDirectory(dir);
            _path = Path.Combine(dir, "desktop_session.log");
            File.WriteAllText(_path, $"--- session {DateTime.Now:O} ---{Environment.NewLine}");
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"SessionLog.Init failed: {ex}");
        }
    }

    public static void Write(string message, Exception? error = null)
    {
        var ts = DateTime.Now.ToString("O");
        var buffer = new System.Text.StringBuilder();
        buffer.Append('[').Append(ts).Append("] ").Append(message);
        if (error is not null)
        {
            buffer.AppendLine();
            buffer.Append("  error: ").Append(error);
        }

        buffer.AppendLine();
        var line = buffer.ToString();
        Debug.Write(line);

        lock (Gate)
        {
            if (_path is null) return;
            try
            {
                File.AppendAllText(_path, line);
            }
            catch
            {
                // ignore file I/O failures
            }
        }
    }
}
