namespace AudioSteg.Core.Audio;

/// <summary>Default stego WAV filename: stego_YYYY_MM_DD_HHMM_{msg_len}.wav</summary>
public static class StegoFileNaming
{
    public static string Build(int msgBitLength, DateTime? timestamp = null)
    {
        var t = timestamp ?? DateTime.Now;
        return $"stego_{t:yyyy_MM_dd_HHmm}_{msgBitLength}.wav";
    }
}
