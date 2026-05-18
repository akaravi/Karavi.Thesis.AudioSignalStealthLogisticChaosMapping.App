using System.IO;
using AudioSteg.Core.Audio;
using NAudio.Wave;

namespace AudioSteg.Desktop.Services;

public sealed class AudioPlaybackService : IDisposable
{
    private WaveOutEvent? _player;

    public void Play(WavFile wav)
    {
        Stop();
        var bytes = wav.Encode();
        using var ms = new MemoryStream(bytes);
        using var reader = new WaveFileReader(ms);
        _player = new WaveOutEvent();
        _player.Init(reader);
        _player.Play();
    }

    public void Stop()
    {
        if (_player is null) return;
        _player.Stop();
        _player.Dispose();
        _player = null;
    }

    public void Dispose() => Stop();
}
