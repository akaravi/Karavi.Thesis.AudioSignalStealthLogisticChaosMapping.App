using AudioStegano.Core.Audio;

namespace AudioStegano.Core.Stego;

/// <summary>Port of <c>train/extract_message.m</c>.</summary>
public sealed class ExtractMessage
{
    public StegoMessageContext Context { get; }

    public ExtractMessage(
        double r = WatermarkDefaults.R,
        double x0 = WatermarkDefaults.X0,
        MessageBlockAutoencoder? autoencoder = null)
    {
        Context = new StegoMessageContext(
            autoencoder ?? TrainedAutoencoder.Instance,
            r,
            x0);
    }

    public string? RunText(WavFile stego, int msgBitLength, byte[]? binKey = null)
    {
        var bits = RunBits(stego, msgBitLength, binKey);
        return bits is null ? null : MessageBits.ToUtf8Text(bits);
    }

    public byte[]? RunBits(WavFile stego, int msgBitLength, byte[]? binKey = null)
    {
        if (msgBitLength <= 0) return [];
        var samples = stego.ToMono().Samples;
        if (msgBitLength > samples.Length) return null;

        var key = binKey ?? LogisticMap.BinaryKey(msgBitLength, Context.X0, Context.R);
        var positions = LogisticPositions.Compute(msgBitLength, samples.Length, Context.X0, Context.R);
        var payload = new byte[msgBitLength];
        for (var i = 0; i < msgBitLength; i++)
        {
            var enc = samples[positions[i]] & 1;
            payload[i] = (byte)((enc ^ key[i]) & 1);
        }
        return Context.RecoverMessageBits(payload);
    }
}
