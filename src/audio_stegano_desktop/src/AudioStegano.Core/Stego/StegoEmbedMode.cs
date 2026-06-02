namespace AudioStegano.Core.Stego;

/// <summary><c>train/embed_message.m</c> <c>embed_mode</c>.</summary>
public enum StegoEmbedMode
{
    XorOnly,
    AeXor,
}

public static class StegoEmbedModeParser
{
    public static StegoEmbedMode FromConfig(string? raw) => (raw ?? "").Trim().ToLowerInvariant() switch
    {
        "ae_xor" or "aexor" or "ae" => StegoEmbedMode.AeXor,
        _ => StegoEmbedMode.XorOnly,
    };

    public static string ToConfigValue(this StegoEmbedMode mode) => mode switch
    {
        StegoEmbedMode.AeXor => "ae_xor",
        _ => "xor_only",
    };
}
