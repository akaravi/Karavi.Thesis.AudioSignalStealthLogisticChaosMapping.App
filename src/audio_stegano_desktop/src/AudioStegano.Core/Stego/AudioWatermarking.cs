using AudioStegano.Core.Audio;

namespace AudioStegano.Core.Stego;

/// <summary>
/// API سازگار با نسخهٔ قبل — دروناً <see cref="EmbedMessage"/> و <see cref="ExtractMessage"/>.
/// </summary>
public sealed class AudioWatermarking
{
    private readonly EmbedMessage _embed;
    private readonly ExtractMessage _extract;

    public double R => _embed.Context.R;
    public double X0 => _embed.Context.X0;
    public StegoEmbedMode EmbedMode => _embed.Context.EmbedMode;
    public MessageBlockAutoencoder? Autoencoder => _embed.Context.Autoencoder;

    public AudioWatermarking(
        double r = WatermarkDefaults.R,
        double x0 = WatermarkDefaults.X0,
        StegoEmbedMode embedMode = StegoEmbedMode.XorOnly,
        MessageBlockAutoencoder? autoencoder = null)
    {
        _embed = new EmbedMessage(r, x0, embedMode, autoencoder);
        _extract = new ExtractMessage(r, x0, embedMode, autoencoder);
    }

    public WatermarkOutcome Embed(string text, WavFile cover, int? fixedMsgBitLength = null) =>
        _embed.RunWithMetrics(text, cover, fixedMsgBitLength);

    public string? Extract(WavFile stego, int msgBitLength) =>
        _extract.RunText(stego, msgBitLength);

    public WatermarkEmbedResult EmbedText(WavFile cover, string text) =>
        _embed.RunText(cover, text);

    public WatermarkEmbedResult EmbedBits(WavFile cover, byte[] binaryMsg, byte[]? binKey = null) =>
        _embed.RunBits(cover, binaryMsg, binKey);

    public byte[]? ExtractBits(WavFile stego, int msgBitLength, byte[]? binKey = null) =>
        _extract.RunBits(stego, msgBitLength, binKey);

    public string? ExtractText(WavFile stego, int msgBitLength) =>
        Extract(stego, msgBitLength);

    public WavFile StegoWithPerturbedKey(WavFile cover, byte[] binaryMsg) =>
        _embed.StegoWithPerturbedKey(cover, binaryMsg);
}
