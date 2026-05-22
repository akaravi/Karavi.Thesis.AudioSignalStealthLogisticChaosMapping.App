namespace AudioStegano.Desktop.Models;

/// <summary>Quality metrics on the embed results card (aligned with evaluate_stego.m).</summary>
public enum EmbedMetricKind
{
    Duration,
    BitsEmbedded,
    Capacity,
    Utilization,
    MsgBitLength,
    Snr,
    Psnr,
    Ber,
    Npcr,
    Uaci,
}
