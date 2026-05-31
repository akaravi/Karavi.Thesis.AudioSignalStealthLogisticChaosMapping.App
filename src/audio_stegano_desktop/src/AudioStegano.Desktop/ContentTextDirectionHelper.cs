using System.Windows;
using System.Windows.Controls;
using AudioStegano.Core.Ui;

namespace AudioStegano.Desktop;

/// Applies content-aware FlowDirection to WPF text input and display controls.
public static class ContentTextDirectionHelper
{
    public static void ApplyTo(TextBox textBox, string? text, bool forceLatinLtr = false)
    {
        textBox.FlowDirection = ResolveFlowDirection(textBox, text, forceLatinLtr);
    }

    public static void ApplyTo(FrameworkElement element, string? text, bool forceLatinLtr = false)
    {
        element.FlowDirection = ResolveFlowDirection(element, text, forceLatinLtr);
    }

    private static FlowDirection ResolveFlowDirection(
        FrameworkElement element,
        string? text,
        bool forceLatinLtr)
    {
        var uiIsRtl = element.FlowDirection == FlowDirection.RightToLeft
            || (element.Parent is FrameworkElement fe && fe.FlowDirection == FlowDirection.RightToLeft)
            || AppState.Settings.Language is AppLanguage.Fa or AppLanguage.Ar;

        return ContentTextDirection.UseLeftToRight(text, forceLatinLtr, uiIsRtl)
            ? FlowDirection.LeftToRight
            : FlowDirection.RightToLeft;
    }
}
