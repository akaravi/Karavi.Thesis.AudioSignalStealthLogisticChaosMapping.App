namespace AudioStegano.Core.Audio;

/// <summary>Downsamples PCM to peak envelopes for UI waveform charts.</summary>
public static class WaveformDisplay
{
    public static IReadOnlyList<double> EnvelopeFromWav(WavFile wav, int maxPoints = 512)
    {
        var mono = wav.ToMono().Samples;
        return EnvelopeFromPcm(mono, maxPoints);
    }

    public static IReadOnlyList<double> EnvelopeFromPcm(ReadOnlySpan<short> samples, int maxPoints = 512)
    {
        if (samples.Length == 0)
            return Array.Empty<double>();

        if (samples.Length <= maxPoints)
        {
            var direct = new double[samples.Length];
            for (var i = 0; i < samples.Length; i++)
                direct[i] = Math.Abs(samples[i]) / 32768.0;
            return direct;
        }

        var outList = new double[maxPoints];
        var step = (double)samples.Length / maxPoints;
        for (var i = 0; i < maxPoints; i++)
        {
            var start = (int)(i * step);
            var end = Math.Min((int)Math.Ceiling((i + 1) * step), samples.Length);
            var peak = 0.0;
            for (var j = start; j < end; j++)
            {
                var v = Math.Abs(samples[j]) / 32768.0;
                if (v > peak) peak = v;
            }
            outList[i] = peak;
        }
        return outList;
    }

    public static double EnvelopePeak(params IReadOnlyList<double>?[] series)
    {
        var peak = 0.0;
        foreach (var s in series)
        {
            if (s is null) continue;
            for (var i = 0; i < s.Count; i++)
            {
                if (s[i] > peak) peak = s[i];
            }
        }
        return peak;
    }

    /// <summary>
    /// Joint peak rescale so quiet recordings fill most of the chart height.
    /// Same gain for every series (fair cover vs stego comparison).
    /// </summary>
    public static IReadOnlyList<double>[] NormalizeForDisplay(
        IReadOnlyList<double>?[] series,
        double targetPeak = 0.92,
        double minPeak = 1e-4)
    {
        var peak = EnvelopePeak(series);
        if (peak < minPeak)
        {
            return series.Select(s => (IReadOnlyList<double>)(s ?? Array.Empty<double>())).ToArray();
        }

        var gain = targetPeak / peak;
        var result = new IReadOnlyList<double>[series.Length];
        for (var i = 0; i < series.Length; i++)
        {
            var src = series[i];
            if (src is null || src.Count == 0)
            {
                result[i] = Array.Empty<double>();
                continue;
            }
            var dst = new double[src.Count];
            for (var j = 0; j < src.Count; j++)
                dst[j] = Math.Clamp(src[j] * gain, 0, 1);
            result[i] = dst;
        }
        return result;
    }
}
