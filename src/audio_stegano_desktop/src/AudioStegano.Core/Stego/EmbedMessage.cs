using AudioStegano.Core.Audio;

namespace AudioStegano.Core.Stego;

/// <summary>Port of <c>train/embed_message.m</c>.</summary>
public sealed class EmbedMessage
{
    public StegoMessageContext Context { get; }

    public EmbedMessage(
        double r = WatermarkDefaults.R,
        double x0 = WatermarkDefaults.X0,
        MessageBlockAutoencoder? autoencoder = null)
    {
        Context = new StegoMessageContext(
            autoencoder ?? TrainedAutoencoder.Instance,
            r,
            x0);
    }

    public WatermarkEmbedResult RunText(WavFile cover, string text) =>
        RunBits(cover, MessageBits.FromUtf8Text(text));

    public WatermarkEmbedResult RunBits(WavFile cover, byte[] binaryMsg, byte[]? binKey = null)
    {
        var key = binKey ?? LogisticMap.BinaryKey(binaryMsg.Length, Context.X0, Context.R);
        if (key.Length != binaryMsg.Length)
            throw new ArgumentException("binKey length must match binaryMsg");

        var mono = cover.ToMono();
        var capacity = mono.Samples.Length;
        if (binaryMsg.Length > capacity)
            throw new ArgumentException(
                $"Message too long: needs {binaryMsg.Length} bits, capacity {capacity}");

        var coverInt = StegoAudioHelper.ToMatlabInt16(mono.Samples);
        var stegoInt = (short[])coverInt.Clone();
        var positions = LogisticPositions.Compute(binaryMsg.Length, capacity, Context.X0, Context.R);
        var payload = Context.BuildPayload(binaryMsg, key);

        for (var i = 0; i < binaryMsg.Length; i++)
        {
            var idx = positions[i];
            var encrypted = payload[i] & 1;
            var v = stegoInt[idx];
            stegoInt[idx] = (short)((v & ~1) | encrypted);
        }

        var payloadFromStego = new byte[binaryMsg.Length];
        for (var i = 0; i < binaryMsg.Length; i++)
            payloadFromStego[i] = (byte)(((stegoInt[positions[i]] & 1) ^ key[i]) & 1);

        var extracted = Context.RecoverMessageBits(payloadFromStego);

        return new WatermarkEmbedResult(
            new WavFile(mono.SampleRate, 1, 16, stegoInt),
            extracted,
            binaryMsg.Length,
            capacity);
    }

    public WavFile StegoWithPerturbedKey(WavFile cover, byte[] binaryMsg)
    {
        var key = LogisticMap.BinaryKey(binaryMsg.Length, Context.X0 + 1e-10, Context.R);
        var mono = cover.ToMono();
        var coverInt = StegoAudioHelper.ToMatlabInt16(mono.Samples);
        var stegoInt = (short[])coverInt.Clone();
        var positions = LogisticPositions.Compute(binaryMsg.Length, mono.Samples.Length, Context.X0 + 1e-10, Context.R);
        var payload = Context.BuildPayload(binaryMsg, key);

        for (var i = 0; i < binaryMsg.Length; i++)
        {
            var idx = positions[i];
            var encrypted = payload[i] & 1;
            var v = stegoInt[idx];
            stegoInt[idx] = (short)((v & ~1) | encrypted);
        }

        return new WavFile(mono.SampleRate, 1, 16, stegoInt);
    }

    public WatermarkOutcome RunWithMetrics(string text, WavFile cover, int? fixedMsgBitLength = null)
    {
        var binaryMsg = fixedMsgBitLength is > 0
            ? MessageBits.FromUtf8TextPadded(text, fixedMsgBitLength.Value)
            : MessageBits.FromUtf8Text(text);
        var embed = RunBits(cover, binaryMsg);
        var stegoDiff = StegoWithPerturbedKey(cover, binaryMsg);
        var coverMono = cover.ToMono();

        var metrics = WatermarkMetrics.Evaluate(
            coverMono.Samples,
            embed.Stego.Samples,
            binaryMsg,
            embed.ExtractedBits,
            stegoDiff.Samples);

        return new WatermarkOutcome(
            embed.Stego,
            metrics,
            embed.BitsEmbedded,
            embed.CapacityBits,
            binaryMsg,
            embed.ExtractedBits);
    }
}

internal static class StegoAudioHelper
{
    public static short[] ToMatlabInt16(ReadOnlySpan<short> samples)
    {
        var outSamples = new short[samples.Length];
        for (var i = 0; i < samples.Length; i++)
        {
            var normalized = samples[i] / 32767.0;
            var v = (int)Math.Round(normalized * 32767);
            v = Math.Clamp(v, -32768, 32767);
            outSamples[i] = (short)v;
        }
        return outSamples;
    }
}
