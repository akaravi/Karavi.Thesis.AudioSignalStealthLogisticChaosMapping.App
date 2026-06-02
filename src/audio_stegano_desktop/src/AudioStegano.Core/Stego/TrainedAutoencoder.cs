namespace AudioStegano.Core.Stego;

/// <summary>Lazy loader for <c>trained_autoencoder.mat</c> weights (embedded JSON).</summary>
public static class TrainedAutoencoder
{
    private static MessageBlockAutoencoder? _cached;

    public static MessageBlockAutoencoder Instance =>
        _cached ??= MessageBlockAutoencoder.LoadEmbedded();
}
