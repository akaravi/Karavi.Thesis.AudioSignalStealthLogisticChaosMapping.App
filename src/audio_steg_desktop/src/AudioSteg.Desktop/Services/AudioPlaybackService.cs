using System.IO;
using AudioSteg.Core.Audio;
using NAudio.Wave;

namespace AudioSteg.Desktop.Services;

public sealed class AudioPlaybackService : IDisposable
{
    private AudioFileReader? _reader;
    private WaveOutEvent? _player;
    private List<double[]>? _spectrumFrames;
    private System.Timers.Timer? _spectrumTimer;

    public bool IsPlaying => _player?.PlaybackState == PlaybackState.Playing;

    public event Action<double[]>? SpectrumBands;

    public void Play(WavFile wav)
    {
        Stop();
        _spectrumFrames = SpectrumAnalyzer.TimelineFromWav(wav);
        var tempPath = Path.Combine(Path.GetTempPath(), $"play_{Guid.NewGuid():N}.wav");
        File.WriteAllBytes(tempPath, wav.Encode());
        _reader = new AudioFileReader(tempPath);
        _player = new WaveOutEvent();
        _player.Init(_reader);
        _player.PlaybackStopped += (_, _) =>
        {
            SpectrumBands?.Invoke(new double[SpectrumAnalyzer.BandCount]);
        };
        _player.Play();

        _spectrumTimer = new System.Timers.Timer(50);
        _spectrumTimer.Elapsed += (_, _) => EmitSpectrumFrame();
        _spectrumTimer.AutoReset = true;
        _spectrumTimer.Start();
    }

    private void EmitSpectrumFrame()
    {
        if (_reader is null || _spectrumFrames is null || _spectrumFrames.Count == 0)
            return;
        var total = _reader.TotalTime.TotalSeconds;
        if (total <= 0) return;
        var pos = _reader.CurrentTime.TotalSeconds;
        var idx = (int)(pos / total * (_spectrumFrames.Count - 1));
        idx = Math.Clamp(idx, 0, _spectrumFrames.Count - 1);
        SpectrumBands?.Invoke(_spectrumFrames[idx]);
    }

    public void Stop()
    {
        _spectrumTimer?.Stop();
        _spectrumTimer?.Dispose();
        _spectrumTimer = null;
        _spectrumFrames = null;

        if (_player is not null)
        {
            _player.Stop();
            _player.Dispose();
            _player = null;
        }

        _reader?.Dispose();
        _reader = null;

        SpectrumBands?.Invoke(new double[SpectrumAnalyzer.BandCount]);
    }

    public void Dispose() => Stop();
}
