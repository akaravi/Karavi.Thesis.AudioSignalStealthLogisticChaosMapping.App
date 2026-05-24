using System.IO;
using System.IO.Pipes;
using System.Text;

namespace AudioStegano.Desktop.Services;

/// <summary>Forwards “open file” launches to the running instance (Explorer Open with / double-click).</summary>
public static class SingleInstanceService
{
    private const string PipeName = "Karavi.AudioStegano.Desktop.OpenFile.v1";
    private static CancellationTokenSource? _cts;
    private static Action<string>? _onPathReceived;

    public static bool TryBecomePrimary()
    {
        try
        {
            using var client = new NamedPipeClientStream(".", PipeName, PipeDirection.Out);
            client.Connect(400);
            return false;
        }
        catch (TimeoutException)
        {
            return true;
        }
        catch
        {
            return true;
        }
    }

    public static void SendPathToPrimary(string path)
    {
        if (string.IsNullOrWhiteSpace(path)) return;
        try
        {
            using var client = new NamedPipeClientStream(".", PipeName, PipeDirection.Out);
            client.Connect(2000);
            using var writer = new StreamWriter(client, Encoding.UTF8) { AutoFlush = true };
            writer.WriteLine(path);
        }
        catch
        {
            // Primary may be exiting; ignore.
        }
    }

    public static void StartServer(Action<string> onPathReceived)
    {
        _onPathReceived = onPathReceived;
        _cts = new CancellationTokenSource();
        var token = _cts.Token;
        _ = Task.Run(async () =>
        {
            while (!token.IsCancellationRequested)
            {
                try
                {
                    await using var server = new NamedPipeServerStream(
                        PipeName,
                        PipeDirection.In,
                        1,
                        PipeTransmissionMode.Byte,
                        PipeOptions.Asynchronous);
                    await server.WaitForConnectionAsync(token).ConfigureAwait(false);
                    using var reader = new StreamReader(server, Encoding.UTF8);
                    var line = await reader.ReadLineAsync(token).ConfigureAwait(false);
                    if (!string.IsNullOrWhiteSpace(line))
                        _onPathReceived?.Invoke(line.Trim());
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch
                {
                    await Task.Delay(200, token).ConfigureAwait(false);
                }
            }
        }, token);
    }

    public static void Stop()
    {
        _cts?.Cancel();
        _cts?.Dispose();
        _cts = null;
        _onPathReceived = null;
    }
}
