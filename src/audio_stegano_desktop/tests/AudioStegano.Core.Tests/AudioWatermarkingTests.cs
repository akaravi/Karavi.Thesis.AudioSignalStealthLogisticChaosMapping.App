using AudioStegano.Core.Audio;
using AudioStegano.Core.Stego;
using Xunit;

namespace AudioStegano.Core.Tests;

public class AudioWatermarkingTests
{
    private static WavFile SineCover(int seconds = 4)
    {
        const int fs = 44100;
        var n = seconds * fs;
        var s = new short[n];
        for (var i = 0; i < n; i++)
        {
            var v = (int)(Math.Sin(2 * Math.PI * 440 * i / fs) * 32700);
            s[i] = (short)Math.Clamp(v, -32768, 32767);
        }
        return new WavFile(fs, 1, 16, s);
    }

    [Fact]
    public void EmbedExtract_RoundTrip_Persian()
    {
        var wm = new AudioWatermarking();
        var cover = SineCover();
        const string msg = "پیام کامل برای حالت دیجیتال.";
        var outcome = wm.Embed(msg, cover);
        var extracted = wm.Extract(outcome.Stego, outcome.BitsEmbedded);
        Assert.Equal(msg, extracted);
    }

    [Fact]
    public void Metrics_BerZero_And_SnrHigh()
    {
        var wm = new AudioWatermarking();
        var cover = SineCover();
        var outcome = wm.Embed("metrics", cover);
        Assert.Equal(0.0, outcome.Metrics.BerPercent);
        Assert.True(outcome.Metrics.SnrDb > 40);
    }

    [Fact]
    public void WrongKey_DoesNotRecover()
    {
        var enc = new AudioWatermarking(x0: 0.45);
        var dec = new AudioWatermarking(x0: 0.46);
        var cover = SineCover();
        var outcome = enc.Embed("Secret", cover);
        var extracted = dec.Extract(outcome.Stego, outcome.BitsEmbedded);
        Assert.NotEqual("Secret", extracted);
    }

    [Fact]
    public void Wav_EncodeDecode_RoundTrip()
    {
        var cover = SineCover(1);
        var bytes = cover.Encode();
        var decoded = WavFile.Decode(bytes);
        Assert.Equal(cover.SampleRate, decoded.SampleRate);
        Assert.Equal(cover.Samples.Length, decoded.Samples.Length);
        for (var i = 0; i < 100; i++)
            Assert.Equal(cover.Samples[i], decoded.Samples[i]);
    }
}
