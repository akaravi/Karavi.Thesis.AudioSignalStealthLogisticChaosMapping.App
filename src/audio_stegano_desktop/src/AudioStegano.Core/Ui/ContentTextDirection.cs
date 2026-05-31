namespace AudioStegano.Core.Ui;

/// Resolves text direction for input/display: Latin-only content stays LTR in RTL UI locales.
public static class ContentTextDirection
{
    private const string RtlScriptPattern =
        @"[\u0590-\u05FF\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]";

    private const string LatinOnlyPattern =
        @"^[\s0-9A-Za-z\u00C0-\u024F\u1E00-\u1EFF.,:;!?@#$%^&*()_+\-=\[\]{}|\\/<>""'`~]*$";

    private static readonly System.Text.RegularExpressions.Regex RtlScript =
        new(RtlScriptPattern, System.Text.RegularExpressions.RegexOptions.Compiled);

    private static readonly System.Text.RegularExpressions.Regex LatinOnly =
        new(LatinOnlyPattern, System.Text.RegularExpressions.RegexOptions.Compiled);

    public static bool ContainsRtlScript(string? text) =>
        !string.IsNullOrEmpty(text) && RtlScript.IsMatch(text);

    public static bool IsLatinOnly(string? text)
    {
        if (string.IsNullOrWhiteSpace(text)) return false;
        if (ContainsRtlScript(text)) return false;
        return LatinOnly.IsMatch(text);
    }

    /// <summary>
    /// True when content should render left-to-right (Latin-only or forced).
    /// </summary>
    public static bool UseLeftToRight(string? text, bool forceLatinLtr = false, bool uiIsRtl = false)
    {
        if (forceLatinLtr) return true;
        if (string.IsNullOrWhiteSpace(text)) return !uiIsRtl;
        if (ContainsRtlScript(text)) return false;
        if (IsLatinOnly(text)) return true;
        return !uiIsRtl;
    }
}
