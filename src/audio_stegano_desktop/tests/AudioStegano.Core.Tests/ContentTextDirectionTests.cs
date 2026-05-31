using AudioStegano.Core.Ui;
using Xunit;

namespace AudioStegano.Core.Tests;

public sealed class ContentTextDirectionTests
{
    [Fact]
    public void LatinOnly_IsLtr_InRtlUi()
    {
        Assert.True(ContentTextDirection.IsLatinOnly("hello 123"));
        Assert.True(ContentTextDirection.UseLeftToRight("3.99", uiIsRtl: true));
    }

    [Fact]
    public void Persian_IsRtl()
    {
        Assert.True(ContentTextDirection.ContainsRtlScript("سلام"));
        Assert.False(ContentTextDirection.UseLeftToRight("سلام", uiIsRtl: true));
    }

    [Fact]
    public void Empty_FollowsUiLocale()
    {
        Assert.False(ContentTextDirection.UseLeftToRight("", uiIsRtl: true));
        Assert.True(ContentTextDirection.UseLeftToRight("", uiIsRtl: false));
    }

    [Fact]
    public void ForceLatinLtr_AlwaysLtr()
    {
        Assert.True(ContentTextDirection.UseLeftToRight("سلام", forceLatinLtr: true, uiIsRtl: true));
    }

    [Theory]
    [InlineData("user@example.com")]
    [InlineData("karavi@ntk.ir")]
    [InlineData("User_Name-123")]
    [InlineData("P@ssw0rd!secret")]
    public void EmailUsernamePassword_IsLtr_InRtlUi(string value)
    {
        Assert.True(ContentTextDirection.IsLatinOnly(value));
        Assert.True(ContentTextDirection.UseLeftToRight(value, uiIsRtl: true));
    }
}
