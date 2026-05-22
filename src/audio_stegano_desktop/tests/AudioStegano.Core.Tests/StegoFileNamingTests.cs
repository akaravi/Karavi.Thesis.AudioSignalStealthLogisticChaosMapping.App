using AudioStegano.Core.Audio;
using Xunit;

namespace AudioStegano.Core.Tests;

public class StegoFileNamingTests
{
    [Fact]
    public void Build_uses_expected_pattern()
    {
        var name = StegoFileNaming.Build(824, new DateTime(2026, 5, 18, 14, 30, 0));
        Assert.Equal("stego_2026_05_18_1430_824.wav", name);
    }
}
