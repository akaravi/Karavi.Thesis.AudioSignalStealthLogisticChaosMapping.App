namespace AudioStegano.Core.Stego;

/// <summary>Payload needs more LSB bits than the cover mono sample capacity.</summary>
public sealed class CapacityExceededException : Exception
{
    public int NeededBits { get; }
    public int AvailableBits { get; }

    public CapacityExceededException(int neededBits, int availableBits)
        : base($"Message too long: needs {neededBits} bits, capacity {availableBits}")
    {
        NeededBits = neededBits;
        AvailableBits = availableBits;
    }

    /// <summary>Parse engine messages: Message too long: needs N bits, capacity M.</summary>
    public static bool TryParse(string? message, out CapacityExceededException? exception)
    {
        exception = null;
        if (string.IsNullOrWhiteSpace(message)) return false;
        var match = System.Text.RegularExpressions.Regex.Match(
            message,
            @"needs\s+(\d+)\s+bits.*?capacity\s+(\d+)",
            System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        if (!match.Success) return false;
        if (!int.TryParse(match.Groups[1].Value, out var needed)) return false;
        if (!int.TryParse(match.Groups[2].Value, out var available)) return false;
        exception = new CapacityExceededException(needed, available);
        return true;
    }
}
