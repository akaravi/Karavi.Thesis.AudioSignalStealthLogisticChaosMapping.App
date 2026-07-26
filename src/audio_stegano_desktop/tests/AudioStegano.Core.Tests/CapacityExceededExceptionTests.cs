using AudioStegano.Core.Stego;
using Xunit;

namespace AudioStegano.Core.Tests;

public class CapacityExceededExceptionTests
{
    [Fact]
    public void TryParse_ExtractsNeededAndAvailable()
    {
        Assert.True(CapacityExceededException.TryParse(
            "Message too long: needs 400000 bits, capacity 144176",
            out var ex));
        Assert.NotNull(ex);
        Assert.Equal(400000, ex!.NeededBits);
        Assert.Equal(144176, ex.AvailableBits);
    }
}
