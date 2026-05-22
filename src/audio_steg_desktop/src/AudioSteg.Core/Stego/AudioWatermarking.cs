using AudioSteg.Core.Audio;

namespace AudioSteg.Core.Stego;

/// <summary>
/// Single entry point for LSB + Logistic-Chaos audio watermarking.
/// Ports: logistic_map_keygen, embed_extract_data, evaluate_stego, main_steganography.
/// </summary>
public sealed class AudioWatermarking
{
    public double R { get; }
    public double X0 { get; }

    public AudioWatermarking(double r = WatermarkDefaults.R, double x0 = WatermarkDefaults.X0)
    {
        R = r;
        X0 = x0;
    }

    public WatermarkOutcome Embed(string text, WavFile cover, int? fixedMsgBitLength = null)
    {
        var binaryMsg = fixedMsgBitLength is > 0
            ? MessageBits.FromUtf8TextPadded(text, fixedMsgBitLength.Value)
            : MessageBits.FromUtf8Text(text);
        var embed = EmbedBits(cover, binaryMsg);
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

    public string? Extract(WavFile stego, int msgBitLength) =>
        ExtractText(stego, msgBitLength);

    public WatermarkEmbedResult EmbedText(WavFile cover, string text) =>
        EmbedBits(cover, MessageBits.FromUtf8Text(text));

    public WatermarkEmbedResult EmbedBits(WavFile cover, byte[] binaryMsg, byte[]? binKey = null)
    {
        var key = binKey ?? LogisticMap.BinaryKey(binaryMsg.Length, X0, R);
        if (key.Length != binaryMsg.Length)
            throw new ArgumentException("binKey length must match binaryMsg");

        var mono = cover.ToMono();
        var capacity = mono.Samples.Length;
        if (binaryMsg.Length > capacity)
            throw new ArgumentException(
                $"Message too long: needs {binaryMsg.Length} bits, capacity {capacity}");

        var coverInt = ToMatlabInt16(mono.Samples);
        var stegoInt = (short[])coverInt.Clone();
        var extracted = new byte[binaryMsg.Length];

        for (var i = 0; i < binaryMsg.Length; i++)
        {
            var encrypted = (binaryMsg[i] ^ key[i]) & 1;
            var v = stegoInt[i];
            stegoInt[i] = (short)(((v & ~1) | encrypted));
            extracted[i] = (byte)(((stegoInt[i] & 1) ^ key[i]) & 1);
        }

        return new WatermarkEmbedResult(
            new WavFile(mono.SampleRate, 1, 16, stegoInt),
            extracted,
            binaryMsg.Length,
            capacity);
    }

    public byte[]? ExtractBits(WavFile stego, int msgBitLength, byte[]? binKey = null)
    {
        if (msgBitLength <= 0) return [];
        var samples = stego.ToMono().Samples;
        if (msgBitLength > samples.Length) return null;

        var key = binKey ?? LogisticMap.BinaryKey(msgBitLength, X0, R);
        var extracted = new byte[msgBitLength];
        for (var i = 0; i < msgBitLength; i++)
        {
            var enc = samples[i] & 1;
            extracted[i] = (byte)((enc ^ key[i]) & 1);
        }
        return extracted;
    }

    public string? ExtractText(WavFile stego, int msgBitLength)
    {
        var bits = ExtractBits(stego, msgBitLength);
        return bits is null ? null : MessageBits.ToUtf8Text(bits);
    }

    public WavFile StegoWithPerturbedKey(WavFile cover, byte[] binaryMsg)
    {
        var key = LogisticMap.BinaryKey(binaryMsg.Length, X0 + 1e-10, R);
        var mono = cover.ToMono();
        var coverInt = ToMatlabInt16(mono.Samples);
        var stegoInt = (short[])coverInt.Clone();

        for (var i = 0; i < binaryMsg.Length; i++)
        {
            var encrypted = (binaryMsg[i] ^ key[i]) & 1;
            var v = stegoInt[i];
            stegoInt[i] = (short)(((v & ~1) | encrypted));
        }

        return new WavFile(mono.SampleRate, 1, 16, stegoInt);
    }

    private static short[] ToMatlabInt16(ReadOnlySpan<short> samples)
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
