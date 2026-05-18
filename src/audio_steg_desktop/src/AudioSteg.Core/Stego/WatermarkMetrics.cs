namespace AudioSteg.Core.Stego;

/// <summary>Port of <c>Matlab/evaluate_stego.m</c>.</summary>
public sealed class WatermarkMetrics
{
    public double SnrDb { get; }
    public double PsnrDb { get; }
    public double BerPercent { get; }
    public double NpcrPercent { get; }
    public double UaciPercent { get; }

    public WatermarkMetrics(double snrDb, double psnrDb, double berPercent, double npcrPercent, double uaciPercent)
    {
        SnrDb = snrDb;
        PsnrDb = psnrDb;
        BerPercent = berPercent;
        NpcrPercent = npcrPercent;
        UaciPercent = uaciPercent;
    }

    public static WatermarkMetrics Evaluate(
        ReadOnlySpan<short> cover,
        ReadOnlySpan<short> stego,
        ReadOnlySpan<byte> originalBits,
        ReadOnlySpan<byte> extractedBits,
        ReadOnlySpan<short> stegoWithDiffKey)
    {
        var n = Math.Min(cover.Length, stego.Length);
        var signalPower = 0.0;
        var noisePower = 0.0;

        for (var i = 0; i < n; i++)
        {
            var x = cover[i] / 32767.0;
            var y = stego[i] / 32767.0;
            signalPower += x * x;
            var d = x - y;
            noisePower += d * d;
        }

        var snr = noisePower == 0 ? double.PositiveInfinity : 10 * Math.Log10(signalPower / noisePower);
        var mse = noisePower / n;
        var psnr = mse == 0 ? double.PositiveInfinity : 10 * Math.Log10(1.0 / mse);

        var m = Math.Min(originalBits.Length, extractedBits.Length);
        var errors = 0;
        for (var i = 0; i < m; i++)
        {
            if ((originalBits[i] & 1) != (extractedBits[i] & 1)) errors++;
        }
        var ber = m == 0 ? 0.0 : (errors / (double)m) * 100.0;

        var len = Math.Min(n, stegoWithDiffKey.Length);
        var diffCount = 0;
        var absSum = 0.0;
        for (var i = 0; i < len; i++)
        {
            var y1 = stego[i] / 32767.0;
            var y2 = stegoWithDiffKey[i] / 32767.0;
            if (y1 != y2) diffCount++;
            absSum += Math.Abs(y1 - y2);
        }
        var npcr = len == 0 ? 0.0 : (diffCount / (double)len) * 100.0;
        var uaci = len == 0 ? 0.0 : (absSum / (len * 2.0)) * 100.0;

        return new WatermarkMetrics(snr, psnr, ber, npcr, uaci);
    }
}
