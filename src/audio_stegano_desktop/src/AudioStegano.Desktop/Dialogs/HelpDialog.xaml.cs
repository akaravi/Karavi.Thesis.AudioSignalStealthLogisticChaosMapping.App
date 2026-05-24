using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using AudioStegano.Desktop.Localization;

namespace AudioStegano.Desktop.Dialogs;

public enum HelpSection { Embed, Extract }

public partial class HelpDialog : Window
{
    public HelpDialog(HelpSection highlightSection)
    {
        InitializeComponent();
        ThemeManager.Apply(this);
        var s = ThemeManager.Strings;
        Title = s.HelpTitle;
        TitleText.Text = s.HelpTitle;
        CloseButton.Content = s.HelpClose;

        AddSection(s.HelpSectionOverview, s.HelpOverviewBody, false);
        AddSection(s.HelpSectionTabs, s.HelpTabsBody, false);
        AddStepsSection(s.HelpSectionEmbedSteps, highlightSection == HelpSection.Embed, [
            s.HelpEmbedStep1, s.HelpEmbedStep2, s.HelpEmbedStep3, s.HelpEmbedStep4,
            s.HelpEmbedStep5, s.HelpEmbedStep6, s.HelpEmbedStep7, s.HelpEmbedStep8,
        ]);
        AddStepsSection(s.HelpSectionExtractSteps, highlightSection == HelpSection.Extract, [
            s.HelpExtractStep1, s.HelpExtractStep2, s.HelpExtractStep3,
            s.HelpExtractStep4, s.HelpExtractStep5, s.HelpExtractStep6,
        ]);
        AddSection(s.HelpSectionTips, s.HelpTipsBody, false);
    }

    private void AddSection(string title, string body, bool highlighted)
    {
        SectionsPanel.Children.Add(BuildCard(title, body, highlighted, numberedSteps: null));
    }

    private void AddStepsSection(string title, bool highlighted, string[] steps)
    {
        SectionsPanel.Children.Add(BuildCard(title, string.Empty, highlighted, steps));
    }

    private static Border BuildCard(string title, string body, bool highlighted, string[]? numberedSteps)
    {
        var border = new Border
        {
            Style = (Style)Application.Current.Resources["MaterialCard"],
            Margin = new Thickness(0, 0, 0, 12),
            Padding = new Thickness(16),
        };
        if (highlighted)
            border.BorderBrush = (Brush)Application.Current.Resources["PrimaryBrush"];

        var stack = new StackPanel();
        stack.Children.Add(new TextBlock
        {
            Text = title,
            Style = (Style)Application.Current.Resources["SectionTitle"],
            Margin = new Thickness(0, 0, 0, 8),
        });

        if (numberedSteps is { Length: > 0 })
        {
            for (var i = 0; i < numberedSteps.Length; i++)
            {
                stack.Children.Add(new TextBlock
                {
                    Text = numberedSteps[i],
                    TextWrapping = TextWrapping.Wrap,
                    Style = (Style)Application.Current.Resources["BodySmall"],
                    Margin = new Thickness(0, 0, 0, 8),
                });
            }
        }
        else if (!string.IsNullOrEmpty(body))
        {
            stack.Children.Add(new TextBlock
            {
                Text = body,
                TextWrapping = TextWrapping.Wrap,
                Style = (Style)Application.Current.Resources["BodySmall"],
            });
        }

        border.Child = stack;
        return border;
    }

    private void CloseButton_Click(object sender, RoutedEventArgs e) => Close();
}
