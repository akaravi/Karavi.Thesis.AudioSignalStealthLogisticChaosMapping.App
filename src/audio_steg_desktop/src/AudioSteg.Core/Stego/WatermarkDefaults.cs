namespace AudioSteg.Core.Stego;

public static class WatermarkDefaults
{
    public const double R = 3.99;
    public const double X0 = 0.45;

    /// <summary>Fallback fixed msg_len (2^18); prefer <c>appsettings.json</c> via AppConfig.</summary>
    public const int DefaultFixedMessageBitLength = 262144;
}
