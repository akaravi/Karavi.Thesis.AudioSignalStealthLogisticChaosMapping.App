using AudioStegano.Core.Audio;
using AudioStegano.Core.Stego;
using Xunit;

namespace AudioStegano.Core.Tests;

public class StegoFixedWavRoundTripTests
{
    private static WavFile SineCover(int seconds = 8)
    {
        const int fs = 44100;
        var n = seconds * fs;
        var s = new short[n];
        for (var i = 0; i < n; i++)
            s[i] = (short)(Math.Sin(2 * Math.PI * 440.0 * i / fs) * 20000);
        return new WavFile(fs, 1, 16, s);
    }

    [Fact]
    public void Fixed262144_Text_SurvivesWavEncodeDecode()
    {
        var wm = new AudioWatermarking();
        var cover = SineCover();
        const string msg = "سلام تست نهان";
        var outcome = wm.Embed(msg, cover, 262144);
        Assert.Equal(0.0, outcome.Metrics.BerPercent);
        Assert.Equal(msg, wm.Extract(outcome.Stego, outcome.BitsEmbedded));

        var reloaded = WavFile.Decode(outcome.Stego.Encode());
        var payload = wm.ExtractPayload(reloaded, outcome.BitsEmbedded);
        Assert.NotNull(payload);
        Assert.Equal(StegoPayloadType.Text, payload!.Type);
        Assert.Equal(msg, payload.Text);
    }

    [Fact]
    public void Fixed262144_Audio_SurvivesWavEncodeDecode_SampleExact()
    {
        var wm = new AudioWatermarking();
        var cover = SineCover();
        var pcm = new short[3000];
        for (var i = 0; i < pcm.Length; i++) pcm[i] = (short)((i % 251) * 120);
        var voice = new WavFile(8000, 1, 16, pcm);
        var expected = PayloadEnvelope.DecodeAudioBody(PayloadEnvelope.EncodeAudioBody(voice));

        var outcome = wm.EmbedAudio(cover, voice, 262144);
        Assert.Equal(0.0, outcome.Metrics.BerPercent);

        var reloaded = WavFile.Decode(outcome.Stego.Encode());
        var payload = wm.ExtractPayload(reloaded, outcome.BitsEmbedded);
        Assert.NotNull(payload?.Audio);
        Assert.Equal(expected.Samples.Length, payload!.Audio!.Samples.Length);
        for (var i = 0; i < expected.Samples.Length; i++)
            Assert.Equal(expected.Samples[i], payload.Audio.Samples[i]);
    }

    [Fact]
    public void Autoencoder_DoesNotCorruptAstgMagic_OnFixedPad()
    {
        var ae = TrainedAutoencoder.Instance;
        var bits = PayloadEnvelope.PackTextBits("Hi", fixedBitLength: 262144);
        var encoded = ae.EncodeRounded(bits);
        var recovered = ae.DecodeBits(encoded.Select(b => (byte)(b & 1)).ToArray());
        // recover path uses decodeBits on XOR result which is AE(msg) style payload
        // actual pipeline: recover = DecodeBits(EncodeRounded(msg) xor-xor) = DecodeBits(EncodeRounded(msg))
        Assert.True(PayloadEnvelope.HasMagicBits(recovered));
        var unpacked = PayloadEnvelope.UnpackBits(recovered);
        Assert.Equal("Hi", unpacked.Text);
    }
}
