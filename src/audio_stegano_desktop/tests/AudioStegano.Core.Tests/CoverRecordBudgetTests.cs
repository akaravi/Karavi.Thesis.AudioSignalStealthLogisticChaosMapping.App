using AudioStegano.Core.Stego;
using Xunit;

namespace AudioStegano.Core.Tests;

public class CoverRecordBudgetTests
{
    [Fact]
    public void RequiredSamples_AddsSafetyMargin()
    {
        Assert.Equal(
            262144 + CoverRecordBudget.SafetySampleMargin,
            CoverRecordBudget.RequiredSamples(262144));
    }

    [Fact]
    public void SamplesSatisfied_GatesOnBufferNotWallClock()
    {
        const int bits = 262144;
        var need = CoverRecordBudget.RequiredSamples(bits);
        Assert.False(CoverRecordBudget.SamplesSatisfied(need - 1, bits));
        Assert.True(CoverRecordBudget.SamplesSatisfied(need, bits));
        Assert.InRange(CoverRecordBudget.ProgressFromSamples(need / 2, bits), 0.49, 0.51);
    }
}
