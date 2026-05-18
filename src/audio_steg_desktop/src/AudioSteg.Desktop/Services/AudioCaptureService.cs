using System.IO;
using AudioSteg.Core.Audio;
using NAudio.Wave;

namespace AudioSteg.Desktop.Services;

public sealed class AudioCaptureService : IDisposable
{
    private WaveInEvent? _waveIn;
    private readonly List<byte> _buffer = [];
    private readonly object _lock = new();
    private bool _recording;

    public bool IsRecording => _recording;

    public event Action<double>? AmplitudeDb;

    public void Start(int sampleRate = 44100)
    {
        Stop();
        _buffer.Clear();
        _waveIn = new WaveInEvent
        {
            WaveFormat = new WaveFormat(sampleRate, 16, 1),
            BufferMilliseconds = 50,
        };
        _waveIn.DataAvailable += OnDataAvailable;
        _waveIn.RecordingStopped += (_, _) => { };
        _waveIn.StartRecording();
        _recording = true;
    }

    public WavFile? StopAndRead(int sampleRate = 44100)
    {
        if (_waveIn is null) return null;
        _waveIn.StopRecording();
        _waveIn.Dispose();
        _waveIn = null;
        _recording = false;

        lock (_lock)
        {
            if (_buffer.Count < 2) return null;
            var sampleCount = _buffer.Count / 2;
            var samples = new short[sampleCount];
            var raw = _buffer.ToArray();
            for (var i = 0; i < sampleCount; i++)
                samples[i] = BitConverter.ToInt16(raw, i * 2);
            return new WavFile(sampleRate, 1, 16, samples);
        }
    }

    private void OnDataAvailable(object? sender, WaveInEventArgs e)
    {
        lock (_lock)
        {
            for (var i = 0; i < e.BytesRecorded; i++)
                _buffer.Add(e.Buffer[i]);
        }

        if (e.BytesRecorded >= 2)
        {
            var sample = BitConverter.ToInt16(e.Buffer, 0);
            var norm = sample / 32768.0;
            var db = 20 * Math.Log10(Math.Max(Math.Abs(norm), 1e-9));
            AmplitudeDb?.Invoke(db);
        }
    }

    public void Dispose() => Stop();

    private void Stop()
    {
        if (_waveIn is null) return;
        try { _waveIn.StopRecording(); } catch { /* ignore */ }
        _waveIn.Dispose();
        _waveIn = null;
        _recording = false;
    }
}
