namespace AudioSteg.Core.Audio;

/// <summary>FFT-style spectrum bands for equalizer UI (32 bars, 0..1).</summary>
public static class SpectrumAnalyzer
{
    public const int BandCount = 32;

    public static double[] BandsFromPcm(ReadOnlySpan<short> samples, int sampleRate = 44100)
    {
        var bands = new double[BandCount];
        if (samples.Length == 0) return bands;

        const int fftSize = 1024;
        var windowed = new double[fftSize];
        var start = samples.Length > fftSize ? samples.Length - fftSize : 0;
        var count = samples.Length - start;
        for (var i = 0; i < fftSize; i++)
        {
            if (i < count)
            {
                var hann = 0.5 - 0.5 * Math.Cos(2 * Math.PI * i / Math.Max(1, count - 1));
                windowed[i] = samples[start + i] / 32768.0 * hann;
            }
        }

        var magnitudes = RealFftMagnitudes(windowed);
        var half = fftSize / 2;
        var nyquist = sampleRate / 2.0;
        const double minHz = 60;
        var maxHz = Math.Min(16000, nyquist);
        var logMin = Math.Log(minHz);
        var logMax = Math.Log(maxHz);

        for (var b = 0; b < BandCount; b++)
        {
            var t0 = (double)b / BandCount;
            var t1 = (double)(b + 1) / BandCount;
            var f0 = Math.Exp(logMin + (logMax - logMin) * t0);
            var f1 = Math.Exp(logMin + (logMax - logMin) * t1);
            var i0 = Math.Clamp((int)(f0 / nyquist * half), 1, half - 1);
            var i1 = Math.Clamp((int)Math.Ceiling(f1 / nyquist * half), i0 + 1, half);
            var peak = 0.0;
            for (var i = i0; i < i1; i++)
                if (magnitudes[i] > peak) peak = magnitudes[i];
            var db = 20 * Math.Log10(peak + 1e-9);
            bands[b] = Math.Clamp((db + 60) / 60, 0, 1);
        }

        return bands;
    }

    public static List<double[]> TimelineFromWav(WavFile wav, int frameMs = 50)
    {
        var mono = wav.ToMono();
        var samples = mono.Samples;
        var rate = mono.SampleRate;
        var frames = new List<double[]>();
        if (samples.Length == 0) return frames;

        var hop = Math.Max(256, rate * frameMs / 1000);
        const int win = 1024;
        for (var i = 0; i + win <= samples.Length; i += hop)
            frames.Add(BandsFromPcm(samples.AsSpan(i, win), rate));

        if (frames.Count == 0 && samples.Length >= 256)
            frames.Add(BandsFromPcm(samples, rate));

        return frames;
    }

    private static double[] RealFftMagnitudes(double[] input)
    {
        var n = input.Length;
        var re = new double[n];
        var im = new double[n];
        Array.Copy(input, re, n);
        FftInPlace(re, im);
        var half = n / 2;
        var mag = new double[half + 1];
        for (var i = 0; i <= half; i++)
            mag[i] = Math.Sqrt(re[i] * re[i] + im[i] * im[i]);
        return mag;
    }

    private static void FftInPlace(double[] re, double[] im)
    {
        var n = re.Length;
        var bits = (int)Math.Log2(n);
        for (var i = 0; i < n; i++)
        {
            var j = BitReverse(i, bits);
            if (j > i)
            {
                (re[i], re[j]) = (re[j], re[i]);
                (im[i], im[j]) = (im[j], im[i]);
            }
        }

        for (var len = 2; len <= n; len <<= 1)
        {
            var ang = -2 * Math.PI / len;
            var wLenRe = Math.Cos(ang);
            var wLenIm = Math.Sin(ang);
            for (var i = 0; i < n; i += len)
            {
                var wRe = 1.0;
                var wIm = 0.0;
                for (var j = 0; j < len / 2; j++)
                {
                    var uRe = re[i + j];
                    var uIm = im[i + j];
                    var vRe = re[i + j + len / 2] * wRe - im[i + j + len / 2] * wIm;
                    var vIm = re[i + j + len / 2] * wIm + im[i + j + len / 2] * wRe;
                    re[i + j] = uRe + vRe;
                    im[i + j] = uIm + vIm;
                    re[i + j + len / 2] = uRe - vRe;
                    im[i + j + len / 2] = uIm - vIm;
                    var nextWRe = wRe * wLenRe - wIm * wLenIm;
                    wIm = wRe * wLenIm + wIm * wLenRe;
                    wRe = nextWRe;
                }
            }
        }
    }

    private static int BitReverse(int x, int bits)
    {
        var y = 0;
        for (var i = 0; i < bits; i++)
        {
            y = (y << 1) | (x & 1);
            x >>= 1;
        }
        return y;
    }
}
