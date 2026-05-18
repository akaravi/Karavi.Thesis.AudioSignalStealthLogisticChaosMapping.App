namespace AudioSteg.Core.Stego;

/// <summary>Port of <c>Matlab/logistic_map_keygen.m</c>.</summary>
public static class LogisticMap
{
    public const double DefaultR = WatermarkDefaults.R;
    public const double DefaultX0 = WatermarkDefaults.X0;

    public static double[] Sequence(int length, double x0 = DefaultX0, double r = DefaultR)
    {
        if (length <= 0) return [];
        if (x0 <= 0.0 || x0 >= 1.0)
            throw new ArgumentOutOfRangeException(nameof(x0), "x0 must be in (0,1)");
        if (r <= 0.0 || r > 4.0)
            throw new ArgumentOutOfRangeException(nameof(r), "r must be in (0,4]");

        var outSeq = new double[length];
        outSeq[0] = r * x0 * (1.0 - x0);
        for (var i = 1; i < length; i++)
        {
            var prev = outSeq[i - 1];
            outSeq[i] = r * prev * (1.0 - prev);
        }
        return outSeq;
    }

    public static byte[] BinaryKey(int length, double x0 = DefaultX0, double r = DefaultR)
    {
        var seq = Sequence(length, x0, r);
        if (seq.Length == 0) return [];
        var sum = 0.0;
        foreach (var v in seq) sum += v;
        var threshold = sum / seq.Length;
        var key = new byte[length];
        for (var i = 0; i < length; i++)
            key[i] = (byte)(seq[i] >= threshold ? 1 : 0);
        return key;
    }
}
