using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Media;
using AudioSteg.Desktop.Localization;

namespace AudioSteg.Desktop.Views;

public partial class AboutView : UserControl
{
    public AboutView()
    {
        InitializeComponent();
        Loaded += (_, _) => ApplyStrings();
    }

    public void ApplyStrings()
    {
        var s = ThemeManager.Strings;
        ProfileTitle.Text = s.AboutProfileTitle;
        ThesisLine.Text = s.AboutThesis;
        BioText.Text = s.AboutBio;
        SupervisorTitle.Text = s.AboutSupervisorSection;
        LinksTitle.Text = s.AboutLinksSection;
        ContactTitle.Text = s.AboutContactSection;
        AlgoTitle.Text = s.AboutTitle;
        AlgoBody.Text = s.AboutAlgoBody;

        SupervisorPanel.Children.Clear();
        SupervisorPanel.Children.Add(CreateInfoRow(s.AboutSupervisorName, "\uE821"));

        LinksPanel.Children.Clear();
        LinksPanel.Children.Add(CreateLinkRow(s.AboutGitHubApp, AboutConstants.GitHubApp));
        LinksPanel.Children.Add(CreateLinkRow(s.AboutGitHubThesis, AboutConstants.GitHubThesis));
        LinksPanel.Children.Add(CreateLinkRow(s.AboutPersonalSite, AboutConstants.PersonalSite));
        LinksPanel.Children.Add(CreateLinkRow(s.AboutCompanySite, AboutConstants.CompanySite));

        ContactPanel.Children.Clear();
        ContactPanel.Children.Add(CreateLinkRow(
            $"{s.AboutPhoneLandline}: {AboutConstants.PhoneLandline}",
            $"tel:{AboutConstants.PhoneLandline}"));
        ContactPanel.Children.Add(CreateLinkRow(
            $"{s.AboutPhoneMobile}: {AboutConstants.PhoneMobile}",
            $"tel:{AboutConstants.PhoneMobile}"));
    }

    private static UIElement CreateInfoRow(string text, string mdl2Icon)
    {
        var panel = new DockPanel { Margin = new Thickness(8, 6, 8, 6), LastChildFill = true };
        var icon = new TextBlock
        {
            FontFamily = new FontFamily("Segoe MDL2 Assets"),
            Text = mdl2Icon,
            FontSize = 16,
            Foreground = (Brush)Application.Current.FindResource("PrimaryBrush"),
            Margin = new Thickness(0, 0, 12, 0),
            VerticalAlignment = VerticalAlignment.Center,
        };
        DockPanel.SetDock(icon, Dock.Left);
        panel.Children.Add(icon);
        panel.Children.Add(new TextBlock
        {
            Text = text,
            TextWrapping = TextWrapping.Wrap,
            VerticalAlignment = VerticalAlignment.Center,
            FontWeight = FontWeights.SemiBold,
            Foreground = (Brush)Application.Current.FindResource("TextBrush"),
        });
        return panel;
    }

    private static UIElement CreateLinkRow(string label, string url)
    {
        var panel = new DockPanel { Margin = new Thickness(8, 6, 8, 6), LastChildFill = true };
        var icon = new TextBlock
        {
            FontFamily = new FontFamily("Segoe MDL2 Assets"),
            Text = "\uE71B",
            FontSize = 16,
            Foreground = (Brush)Application.Current.FindResource("PrimaryBrush"),
            Margin = new Thickness(0, 0, 12, 0),
            VerticalAlignment = VerticalAlignment.Center,
        };
        DockPanel.SetDock(icon, Dock.Left);
        panel.Children.Add(icon);

        var link = new TextBlock
        {
            TextWrapping = TextWrapping.Wrap,
            VerticalAlignment = VerticalAlignment.Center,
        };
        var href = new Hyperlink(new Run(label)) { NavigateUri = new Uri(url) };
        href.RequestNavigate += (_, e) =>
        {
            try
            {
                Process.Start(new ProcessStartInfo(e.Uri.AbsoluteUri) { UseShellExecute = true });
            }
            catch
            {
                MessageBox.Show(url, label, MessageBoxButton.OK, MessageBoxImage.Warning);
            }
        };
        link.Inlines.Add(href);
        panel.Children.Add(link);
        return panel;
    }
}
