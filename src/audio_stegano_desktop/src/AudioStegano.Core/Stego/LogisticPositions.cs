namespace AudioStegano.Core.Stego;

/// <summary>
/// Port of <c>train/logistic_positions.m</c> — chaotic sample indices for LSB embedding.
/// </summary>
public static class LogisticPositions
{
    /// <summary>
    /// Returns <paramref name="n"/> distinct 0-based sample indices in [0, <paramref name="maxPos"/>).
    /// </summary>
    public static int[] Compute(int n, int maxPos, double x0 = LogisticMap.DefaultX0, double r = LogisticMap.DefaultR)
    {
        if (n <= 0) return [];
        if (maxPos <= 0)
            throw new ArgumentOutOfRangeException(nameof(maxPos), "maxPos must be positive");
        if (n > maxPos)
            throw new ArgumentException($"Need {n} distinct positions but signal has only {maxPos} samples.");
        if (x0 <= 0.0 || x0 >= 1.0)
            throw new ArgumentOutOfRangeException(nameof(x0), "x0 must be in (0,1)");
        if (r <= 0.0 || r > 4.0)
            throw new ArgumentOutOfRangeException(nameof(r), "r must be in (0,4]");

        var raw = new int[n];
        var x = x0;
        for (var i = 0; i < n; i++)
        {
            x = r * x * (1.0 - x);
            var matlabIdx = Math.Max(1, (int)Math.Floor(x * maxPos));
            raw[i] = matlabIdx - 1;
        }

        var unique = raw.Distinct().OrderBy(v => v).ToList();
        if (unique.Count < n)
        {
            var used = new HashSet<int>(unique);
            for (var i = 0; i < maxPos && unique.Count < n; i++)
            {
                if (used.Add(i))
                    unique.Add(i);
            }
        }

        unique.Sort();
        return unique.Take(n).ToArray();
    }
}
