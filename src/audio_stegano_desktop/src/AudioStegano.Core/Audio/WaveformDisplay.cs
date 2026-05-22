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
}
