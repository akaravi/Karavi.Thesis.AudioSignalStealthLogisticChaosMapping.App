using AudioStegano.Core.Audio;
using AudioStegano.Core.Stego;
using Xunit;

namespace AudioStegano.Core.Tests;

public class AudioPayloadDurationTests
{
    private static short[] Tone(int sampleRate, double seconds, double hz = 440, short amplitude = 8000)
    {
        var n = (int)Math.Round(sampleRate * seconds);
        var pcm = new short[n];
        for (var i = 0; i < n; i++)
        {
            var v = Math.Sin(2 * Math.PI * hz * i / sampleRate) * amplitude;
            pcm[i] = (short)Math.Clamp((int)Math.Round(v), short.MinValue, short.MaxValue);
        }
        return pcm;
    }

    [Fact]
    public void Reconcile_Retags_8kCapture_WronglyLabeled_44100()
    {
        var pcm = Tone(8000, 2);
        var wrong = new WavFile(44100, 1, 16, pcm);
        var corrected = SampleRateReconcile.Reconcile(wrong, TimeSpan.FromSeconds(2));
        Assert.Equal(8000, corrected.SampleRate);
    }

    [Fact]
    public void WrongLabel_44100_On_8kCapture_Encode_MakesSpeechTooFast()
    {
        var pcm = Tone(8000, 2);
        var wrong = new WavFile(44100, 1, 16, pcm);
        var recovered = PayloadEnvelope.DecodeAudioBody(PayloadEnvelope.EncodeAudioBody(wrong));
        var dur = SampleRateReconcile.DurationSeconds(recovered);
        Assert.True(dur < 0.6, $"expected fast/shrunk duration, got {dur}");
    }

    [Fact]
    public void Correct_8kHz_Label_Preserves_Duration_AfterEncodeDecode()
    {
        var pcm = Tone(8000, 2);
        var wav = new WavFile(8000, 1, 16, pcm);
        var recovered = PayloadEnvelope.DecodeAudioBody(PayloadEnvelope.EncodeAudioBody(wav));
        var dur = SampleRateReconcile.DurationSeconds(recovered);
        Assert.InRange(dur, 1.95, 2.05);
    }

    [Fact]
    public void Reconcile_Then_Encode_Preserves_WallClock_Duration()
    {
        var pcm = Tone(8000, 2);
        var wrong = new WavFile(44100, 1, 16, pcm);
        var corrected = SampleRateReconcile.Reconcile(wrong, TimeSpan.FromSeconds(2));
        var recovered = PayloadEnvelope.DecodeAudioBody(PayloadEnvelope.EncodeAudioBody(corrected));
        Assert.InRange(SampleRateReconcile.DurationSeconds(recovered), 1.95, 2.05);
    }

    [Fact]
    public void PrepareAudioForExport_Preserves_Duration()
    {
        var pcm = Tone(8000, 1.5);
        var wav = new WavFile(8000, 1, 16, pcm);
        var body = PayloadEnvelope.DecodeAudioBody(PayloadEnvelope.EncodeAudioBody(wav));
        var exported = PayloadEnvelope.PrepareAudioForExport(body);
        Assert.Equal(PayloadAudioDefaults.ExportSampleRate, exported.SampleRate);
        Assert.InRange(SampleRateReconcile.DurationSeconds(exported), 1.46, 1.54);
    }
}
