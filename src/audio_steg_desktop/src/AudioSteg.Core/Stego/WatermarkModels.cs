using AudioSteg.Core.Audio;

namespace AudioSteg.Core.Stego;

public sealed class WatermarkEmbedResult
{
    public WavFile Stego { get; }
    public byte[] ExtractedBits { get; }
    public int BitsEmbedded { get; }
    public int CapacityBits { get; }

    public WatermarkEmbedResult(WavFile stego, byte[] extractedBits, int bitsEmbedded, int capacityBits)
    {
        Stego = stego;
        ExtractedBits = extractedBits;
        BitsEmbedded = bitsEmbedded;
        CapacityBits = capacityBits;
    }
}

public sealed class WatermarkOutcome
{
    public WavFile Stego { get; }
    public WatermarkMetrics Metrics { get; }
    public int BitsEmbedded { get; }
    public int CapacityBits { get; }
    public byte[] OriginalBits { get; }
    public byte[] ExtractedBits { get; }

    public WatermarkOutcome(
        WavFile stego,
        WatermarkMetrics metrics,
        int bitsEmbedded,
        int capacityBits,
        byte[] originalBits,
        byte[] extractedBits)
    {
        Stego = stego;
        Metrics = metrics;
        BitsEmbedded = bitsEmbedded;
        CapacityBits = capacityBits;
        OriginalBits = originalBits;
        ExtractedBits = extractedBits;
    }

    public double Utilization =>
        CapacityBits == 0 ? 0.0 : Math.Clamp(BitsEmbedded / (double)CapacityBits, 0.0, 1.0);
}
