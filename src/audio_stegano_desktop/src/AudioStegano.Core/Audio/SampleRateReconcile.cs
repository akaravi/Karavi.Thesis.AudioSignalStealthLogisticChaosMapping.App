namespace AudioStegano.Core.Audio;

/// <summary>
/// Corrects a mis-labeled PCM <see cref="WavFile"/> using wall-clock capture duration.
/// Example bug: capture at 8 kHz but header stamped 44100 → encode downsamples and
/// recovered speech plays ~5.5× too fast.
/// </summary>
public static class SampleRateReconcile
{
    public static readonly int[] CommonRates =
        [8000, 11025, 16000, 22050, 32000, 44100, 48000];

    public const double MismatchRatio = 0.15;

    public static WavFile Reconcile(WavFile wav, TimeSpan? wallClock)
    {
        if (wallClock is null || wallClock.Value.TotalMilliseconds < 250)
            return wav;
        if (wav.Samples.Length == 0)
            return wav;

        var implied = wav.Samples.Length * 1000.0 / wallClock.Value.TotalMilliseconds;
        if (implied < 1000)
            return wav;

        var labeledErr = Math.Abs(implied - wav.SampleRate) / implied;
        if (labeledErr <= MismatchRatio)
            return wav;

        var best = CommonRates[0];
        var bestErr = Math.Abs(implied - best);
        foreach (var rate in CommonRates)
        {
            var err = Math.Abs(implied - rate);
            if (err < bestErr)
            {
                bestErr = err;
                best = rate;
            }
        }

        if (best == wav.SampleRate)
            return wav;

        return new WavFile(best, wav.NumChannels, wav.BitsPerSample, (short[])wav.Samples.Clone());
    }

    public static double DurationSeconds(WavFile wav)
    {
        if (wav.SampleRate <= 0 || wav.Samples.Length == 0)
            return 0;
        var ch = wav.NumChannels < 1 ? 1 : wav.NumChannels;
        var frames = wav.Samples.Length / ch;
        return frames / (double)wav.SampleRate;
    }
}
