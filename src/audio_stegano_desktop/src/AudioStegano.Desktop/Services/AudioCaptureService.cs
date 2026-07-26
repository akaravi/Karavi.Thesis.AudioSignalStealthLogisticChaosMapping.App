using System.IO;
using AudioStegano.Core.Audio;
using NAudio.Wave;

namespace AudioStegano.Desktop.Services;

public sealed class AudioCaptureService : IDisposable
{
    private WaveInEvent? _waveIn;
    private readonly List<byte> _buffer = [];
    private readonly object _lock = new();
    private bool _recording;
    private int _sampleRate = 44100;

    public bool IsRecording => _recording;

    /// <summary>Sample rate of the active or last started capture session.</summary>
    public int SampleRate => _sampleRate;

    public event Action<double>? AmplitudeDb;
    public event Action<double[]>? SpectrumBands;

    private DateTime _lastSpectrumUtc = DateTime.MinValue;

    public void Start(int sampleRate = 44100)
    {
        Stop();
        _buffer.Clear();
        _sampleRate = sampleRate;
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

    /// <summary>
    /// Stops capture and builds a WAV using the session sample rate from <see cref="Start"/>.
    /// Do not pass a different rate unless intentionally re-labeling.
    /// </summary>
    public WavFile? StopAndRead(int? sampleRate = null)
    {
        if (_waveIn is null) return null;
        _waveIn.StopRecording();
        _waveIn.Dispose();
        _waveIn = null;
        _recording = false;

        var rate = sampleRate ?? _sampleRate;
        lock (_lock)
        {
            if (_buffer.Count < 2) return null;
            var sampleCount = _buffer.Count / 2;
            var samples = new short[sampleCount];
            var raw = _buffer.ToArray();
            for (var i = 0; i < sampleCount; i++)
                samples[i] = BitConverter.ToInt16(raw, i * 2);
            return new WavFile(rate, 1, 16, samples);
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

        EmitSpectrum();
    }

    private void EmitSpectrum()
    {
        var now = DateTime.UtcNow;
        if ((now - _lastSpectrumUtc).TotalMilliseconds < 50) return;

        short[] snapshot;
        lock (_lock)
        {
            if (_buffer.Count < 512) return;
            const int take = 2048;
            var start = _buffer.Count > take ? _buffer.Count - take : 0;
            var len = _buffer.Count - start;
            var count = len / 2;
            if (count < 256) return;
            snapshot = new short[count];
            for (var i = 0; i < count; i++)
                snapshot[i] = BitConverter.ToInt16(_buffer.ToArray(), start + i * 2);
        }

        _lastSpectrumUtc = now;
        SpectrumBands?.Invoke(SpectrumAnalyzer.BandsFromPcm(snapshot));
    }

    /// <summary>Stops recording and discards captured samples (Flutter <c>cancel()</c> parity).</summary>
    public void Cancel()
    {
        Stop();
        lock (_lock)
            _buffer.Clear();
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
