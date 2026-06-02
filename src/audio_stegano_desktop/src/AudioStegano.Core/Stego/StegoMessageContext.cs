namespace AudioStegano.Core.Stego;

/// <summary>Shared parameters for <c>embed_message.m</c> / <c>extract_message.m</c>.</summary>
public sealed class StegoMessageContext
{
    public double R { get; }
    public double X0 { get; }
    public StegoEmbedMode EmbedMode { get; }
    public MessageBlockAutoencoder? Autoencoder { get; }

    public StegoMessageContext(
        double r = WatermarkDefaults.R,
        double x0 = WatermarkDefaults.X0,
        StegoEmbedMode embedMode = StegoEmbedMode.XorOnly,
        MessageBlockAutoencoder? autoencoder = null)
    {
        R = r;
        X0 = x0;
        EmbedMode = embedMode;
        Autoencoder = autoencoder;
        if (embedMode == StegoEmbedMode.AeXor && autoencoder is null)
            throw new ArgumentException("autoencoder is required when embedMode is ae_xor");
    }

    public byte[] BuildPayload(byte[] binaryMsg, byte[] key)
    {
        if (EmbedMode == StegoEmbedMode.AeXor)
        {
            var encoded = Autoencoder!.EncodeRounded(binaryMsg);
            return MessageBlockAutoencoder.BuildPayload(encoded, key);
        }

        var payload = new byte[binaryMsg.Length];
        for (var i = 0; i < binaryMsg.Length; i++)
            payload[i] = (byte)((binaryMsg[i] ^ key[i]) & 1);
        return payload;
    }

    public byte[] RecoverMessageBits(byte[] payload) =>
        EmbedMode == StegoEmbedMode.AeXor
            ? Autoencoder!.DecodeBits(payload)
            : payload;
}
