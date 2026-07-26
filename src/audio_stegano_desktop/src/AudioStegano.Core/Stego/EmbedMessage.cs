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
        RunBits(cover, PayloadEnvelope.PackTextBits(text));

    public WatermarkEmbedResult RunAudio(WavFile cover, WavFile payloadAudio, int? fixedMsgBitLength = null) =>
        RunBits(cover, PayloadEnvelope.PackAudioBits(payloadAudio, fixedBitLength: fixedMsgBitLength));

    public WatermarkEmbedResult RunBits(WavFile cover, byte[] binaryMsg, byte[]? binKey = null)
    {
        var key = binKey ?? LogisticMap.BinaryKey(binaryMsg.Length, Context.X0, Context.R);
        if (key.Length != binaryMsg.Length)
            throw new ArgumentException("binKey length must match binaryMsg");

        var mono = cover.ToMono();
        var capacity = mono.Samples.Length;
        if (binaryMsg.Length > capacity)
            throw new CapacityExceededException(binaryMsg.Length, capacity);

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
        var binaryMsg = PayloadEnvelope.PackTextBits(
            text,
            fixedBitLength: fixedMsgBitLength is > 0 ? fixedMsgBitLength : null);
        return RunWithMetricsBits(cover, binaryMsg);
    }

    public WatermarkOutcome RunWithMetricsBits(WavFile cover, byte[] binaryMsg)
    {
        var embed = RunBits(cover, binaryMsg);
        var stegoDiff = StegoWithPerturbedKey(cover, binaryMsg);
        var coverMono = StegoAudioHelper.ToMatlabInt16(cover.ToMono().Samples);

        var metrics = WatermarkMetrics.Evaluate(
            coverMono,
            embed.Stego.Samples,
            binaryMsg,
            embed.ExtractedBits,
            stegoDiff.Samples);

        EmbedIntegrity.AssertOk(
            EmbedIntegrity.Verify(
                cover,
                embed.Stego,
                binaryMsg,
                embed.ExtractedBits,
                metrics.BerPercent,
                Context.R,
                Context.X0,
                Context.Autoencoder));

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
        // Identity copy — keep PCM values bit-exact vs cover (only LSB embed may change).
        return samples.ToArray();
    }
}
