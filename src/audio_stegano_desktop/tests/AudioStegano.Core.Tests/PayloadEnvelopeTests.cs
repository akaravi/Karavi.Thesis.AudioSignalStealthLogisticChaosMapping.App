using AudioStegano.Core.Audio;
using AudioStegano.Core.Stego;
using Xunit;

namespace AudioStegano.Core.Tests;

public class PayloadEnvelopeTests
{
    [Fact]
    public void PackUnpack_Text_RoundTrip()
    {
        const string msg = "سلام hello";
        var bits = PayloadEnvelope.PackTextBits(msg);
        Assert.Equal(0, bits.Length % 8);
        Assert.True(PayloadEnvelope.HasMagicBits(bits));
        var result = PayloadEnvelope.UnpackBits(bits);
        Assert.False(result.IsLegacy);
        Assert.Equal(StegoPayloadType.Text, result.Type);
        Assert.Equal(msg, result.Text);
    }

    [Fact]
    public void FixedPad_Then_Unpack_Text()
    {
        var bits = PayloadEnvelope.PackTextBits("hi", fixedBitLength: 2048);
        Assert.Equal(2048, bits.Length);
        Assert.Equal("hi", PayloadEnvelope.UnpackBits(bits).Text);
    }

    [Fact]
    public void LegacyBits_WithoutMagic_DecodeAsUtf8()
    {
        var legacy = MessageBits.FromUtf8Text("legacy");
        Assert.False(PayloadEnvelope.HasMagicBits(legacy));
        var result = PayloadEnvelope.UnpackBits(legacy);
        Assert.True(result.IsLegacy);
        Assert.Equal("legacy", result.Text);
    }

    [Fact]
    public void AudioBody_EncodeDecode_SampleCount()
    {
        var pcm = new short[800];
        for (var i = 0; i < pcm.Length; i++)
            pcm[i] = (short)((i % 256) * 100);
        var wav = new WavFile(8000, 1, 16, pcm);
        var bits = PayloadEnvelope.PackAudioBits(wav);
        var result = PayloadEnvelope.UnpackBits(bits);
        Assert.Equal(StegoPayloadType.Audio, result.Type);
        Assert.NotNull(result.Audio);
        Assert.Equal(8000, result.Audio!.SampleRate);
        Assert.Equal(800, result.Audio.Samples.Length);
    }

    [Fact]
    public void QuietSpeech_PeakNormalize_KeepsAudibleEnergy()
    {
        var pcm = new short[1600];
        for (var i = 0; i < pcm.Length; i++)
            pcm[i] = (short)((i % 40) < 20 ? 400 : -400);
        var wav = new WavFile(8000, 1, 16, pcm);
        var recovered = PayloadEnvelope.DecodeAudioBody(PayloadEnvelope.EncodeAudioBody(wav));
        var peak = 0;
        foreach (var s in recovered.Samples)
        {
            var a = Math.Abs((int)s);
            if (a > peak) peak = a;
        }
        Assert.True(peak > 200);
    }

    [Fact]
    public void PrepareAudioForExport_UpsamplesTo16kHz()
    {
        var pcm = new short[800];
        for (var i = 0; i < pcm.Length; i++)
            pcm[i] = (short)((i % 50) * 200);
        var wav = new WavFile(8000, 1, 16, pcm);
        var exported = PayloadEnvelope.PrepareAudioForExport(wav);
        Assert.Equal(PayloadAudioDefaults.ExportSampleRate, exported.SampleRate);
        Assert.True(exported.Samples.Length > pcm.Length);
    }
}
