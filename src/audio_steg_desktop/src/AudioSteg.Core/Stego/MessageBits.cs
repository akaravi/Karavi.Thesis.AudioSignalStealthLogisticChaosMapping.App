using System.Text;

namespace AudioSteg.Core.Stego;

/// <summary>UTF-8 text ↔ raw bit stream (main_steganography.m binary_msg).</summary>
public static class MessageBits
{
    public static byte[] FromUtf8Text(string text)
    {
        var bytes = Encoding.UTF8.GetBytes(text);
        var outBits = new byte[bytes.Length * 8];
        var pos = 0;
        foreach (var b in bytes)
        {
            for (var bit = 7; bit >= 0; bit--)
                outBits[pos++] = (byte)((b >> bit) & 1);
        }
        return outBits;
    }

    public static string? ToUtf8Text(byte[] bits)
    {
        if (bits.Length == 0) return string.Empty;
        if (bits.Length % 8 != 0) return null;

        var bytes = new byte[bits.Length / 8];
        var pos = 0;
        for (var i = 0; i < bytes.Length; i++)
        {
            var b = 0;
            for (var bit = 0; bit < 8; bit++)
                b = (b << 1) | (bits[pos++] & 1);
            bytes[i] = (byte)b;
        }
        return Encoding.UTF8.GetString(bytes);
    }

    public static int BitLengthForText(string text) => FromUtf8Text(text).Length;
}
