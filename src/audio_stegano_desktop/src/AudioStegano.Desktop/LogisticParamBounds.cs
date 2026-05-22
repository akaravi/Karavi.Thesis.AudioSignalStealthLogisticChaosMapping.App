namespace AudioStegano.Desktop;

/// <summary>UI bounds for logistic map parameters (matches Flutter / MATLAB port).</summary>
public static class LogisticParamBounds
{
    public const double RMin = 3.5;
    public const double RMax = 4.0;
    public const double X0Min = 0.01;
    public const double X0Max = 0.99;

    public static double ClampR(double value) => Math.Clamp(value, RMin, RMax);
    public static double ClampX0(double value) => Math.Clamp(value, X0Min, X0Max);

    public static bool TryParseR(string text, out double result)
    {
        result = 0;
        if (!TryParse(text, out var v) || v <= 0 || v > 4.0) return false;
        result = ClampR(v);
        return true;
    }

    public static bool TryParseX0(string text, out double result)
    {
        result = 0;
        if (!TryParse(text, out var v) || v <= 0 || v >= 1.0) return false;
        result = ClampX0(v);
        return true;
    }

    private static bool TryParse(string text, out double value)
    {
        value = 0;
        var t = text.Trim().Replace(',', '.');
        return double.TryParse(t, System.Globalization.NumberStyles.Float,
            System.Globalization.CultureInfo.InvariantCulture, out value);
    }
}
