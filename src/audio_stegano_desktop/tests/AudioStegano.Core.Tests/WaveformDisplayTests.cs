using AudioStegano.Core.Audio;
using Xunit;

namespace AudioStegano.Core.Tests;

public class WaveformDisplayTests
{
    [Fact]
    public void NormalizeForDisplay_ScalesQuietPeaksNearTarget()
    {
        var cover = Enumerable.Repeat(0.05, 8).ToArray();
        var stego = Enumerable.Repeat(0.04, 8).ToArray();
        var outNorm = WaveformDisplay.NormalizeForDisplay([cover, stego], targetPeak: 0.92);
        Assert.Equal(0.92, outNorm[0][0], 3);
        Assert.Equal(0.92 * 0.04 / 0.05, outNorm[1][0], 3);
    }

    [Fact]
    public void EnvelopePeak_ReturnsJointMax()
    {
        Assert.Equal(0.2, WaveformDisplay.EnvelopePeak(
            new[] { 0.1, 0.2 },
            new[] { 0.15, 0.05 }));
    }
}
