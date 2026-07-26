namespace AudioStegano.Core.Stego;

/// <summary>
/// Minimum cover-recording budget so LSB capacity ≥ requiredBits (1 bit / mono sample).
/// Gate on buffered sample count — wall-clock alone can undershoot on slow capture.
/// </summary>
public static class CoverRecordBudget
{
    public const int CoverSampleRate = 44100;

    /// <summary>Extra mono samples beyond the bit budget (≈100 ms at 44.1 kHz).</summary>
    public const int SafetySampleMargin = 4410;

    public static int RequiredSamples(int requiredBits)
    {
        if (requiredBits <= 0) return 0;
        return requiredBits + SafetySampleMargin;
    }

    /// <summary>Wall-clock estimate with safety factor (UI hint only).</summary>
    public static TimeSpan MinDuration(
        int requiredBits,
        int sampleRate = CoverSampleRate,
        double safetyFactor = 1.35)
    {
        if (requiredBits <= 0 || sampleRate <= 0)
            return TimeSpan.Zero;
        var samples = RequiredSamples(requiredBits);
        return TimeSpan.FromSeconds(samples * safetyFactor / sampleRate);
    }

    public static double ProgressFromSamples(int bufferedSamples, int requiredBits)
    {
        var need = RequiredSamples(requiredBits);
        if (need <= 0) return 1;
        var p = bufferedSamples / (double)need;
        if (double.IsNaN(p) || double.IsInfinity(p)) return 0;
        return Math.Clamp(p, 0, 1);
    }

    public static bool SamplesSatisfied(int bufferedSamples, int requiredBits) =>
        bufferedSamples >= RequiredSamples(requiredBits);

    public static TimeSpan RemainingFromSamples(
        int bufferedSamples,
        int requiredBits,
        int sampleRate = CoverSampleRate)
    {
        var need = RequiredSamples(requiredBits) - bufferedSamples;
        if (need <= 0 || sampleRate <= 0) return TimeSpan.Zero;
        return TimeSpan.FromSeconds(need / (double)sampleRate);
    }
}
