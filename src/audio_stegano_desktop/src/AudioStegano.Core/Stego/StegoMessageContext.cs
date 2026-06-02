using System.Text.Json;

namespace AudioStegano.Core.Stego;

/// <summary>Shared parameters for <c>embed_message.m</c> / <c>extract_message.m</c>.</summary>
public sealed class StegoMessageContext
{
    public double R { get; }
    public double X0 { get; }
    public MessageBlockAutoencoder Autoencoder { get; }

    public StegoMessageContext(
        MessageBlockAutoencoder autoencoder,
        double r = WatermarkDefaults.R,
        double x0 = WatermarkDefaults.X0)
    {
        R = r;
        X0 = x0;
        Autoencoder = autoencoder ?? throw new ArgumentNullException(nameof(autoencoder));
    }

    public byte[] BuildPayload(byte[] binaryMsg, byte[] key)
    {
        var encoded = Autoencoder.EncodeRounded(binaryMsg);
        return MessageBlockAutoencoder.BuildPayload(encoded, key);
    }

    public byte[] RecoverMessageBits(byte[] payload) => Autoencoder.DecodeBits(payload);
}
