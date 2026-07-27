using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using AudioStegano.Desktop.Localization;

namespace AudioStegano.Desktop.Views;

public partial class AboutView : UserControl
{
    public AboutView()
    {
        InitializeComponent();
        ProfilePhoto.Source = new BitmapImage(new Uri(AboutConstants.ProfilePhotoPackUri));
        Loaded += (_, _) => ApplyStrings();
    }

    public void ApplyStrings()
    {
        var s = ThemeManager.Strings;
        ProfileTitle.Text = s.AboutProfileTitle;
        ThesisLine.Text = s.AboutThesis;
        VersionLine.Text = $"{s.AboutVersion}: {AppVersion.Display}";
        BioText.Text = s.AboutBio;
        SupervisorTitle.Text = s.AboutSupervisorSection;
        LinksTitle.Text = s.AboutLinksSection;
        ContactTitle.Text = s.AboutContactSection;
        AlgoTitle.Text = s.AboutTitle;
        AlgoBody.Text = s.AboutAlgoBody;

        SupervisorPanel.Children.Clear();
        SupervisorPanel.Children.Add(CreateInfoRow(s.AboutSupervisorName, "\uE821", "IconThesisBrush"));

        LinksPanel.Children.Clear();
        LinksPanel.Children.Add(CreateLinkRow(s.AboutGitHubApp, AboutConstants.GitHubApp, "\uE943", "IconGithubBrush"));
        LinksPanel.Children.Add(CreateLinkRow(s.AboutGitHubThesis, AboutConstants.GitHubThesis, "\uE821", "IconThesisBrush"));
        LinksPanel.Children.Add(CreateLinkRow(s.AboutPersonalSite, AboutConstants.PersonalSite, "\uE774", "IconWebBrush"));
        LinksPanel.Children.Add(CreateLinkRow(s.AboutCompanySite, AboutConstants.CompanySite, "\uE80F", "IconCompanyBrush"));

        ContactPanel.Children.Clear();
        ContactPanel.Children.Add(CreateContactRow(
            s.AboutCall,
            AboutConstants.PhoneNumber,
            $"tel:{AboutConstants.PhoneNumber}",
            "\uE717",
            "IconPhoneBrush"));
        ContactPanel.Children.Add(CreateContactRow(
            s.AboutEmail,
            AboutConstants.Email,
            $"mailto:{AboutConstants.Email}",
            "\uE715",
            "IconEmailBrush"));
    }

    private static UIElement CreateContactRow(
        string label,
        string latinValue,
        string url,
        string mdl2Icon,
        string brushKey)
    {
        var root = new DockPanel { Margin = new Thickness(8, 6, 8, 6), LastChildFill = true };
        root.Children.Add(CreateAccentIcon(mdl2Icon, brushKey));

        var panel = new StackPanel();
        panel.Children.Add(new TextBlock
        {
            Text = label,
            TextWrapping = TextWrapping.Wrap,
            FontWeight = FontWeights.SemiBold,
            Foreground = (Brush)Application.Current.FindResource("TextBrush"),
            Margin = new Thickness(0, 0, 0, 2),
        });

        var valueHost = new TextBlock { TextWrapping = TextWrapping.Wrap };
        ContentTextDirectionHelper.ApplyTo(valueHost, latinValue, forceLatinLtr: true);
        var href = new Hyperlink(new Run(latinValue)) { NavigateUri = new Uri(url) };
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
        valueHost.Inlines.Add(href);
        panel.Children.Add(valueHost);
        root.Children.Add(panel);
        return root;
    }

    private static UIElement CreateInfoRow(string text, string mdl2Icon, string brushKey)
    {
        var panel = new DockPanel { Margin = new Thickness(8, 6, 8, 6), LastChildFill = true };
        panel.Children.Add(CreateAccentIcon(mdl2Icon, brushKey));
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

    private static UIElement CreateLinkRow(string label, string url, string mdl2Icon, string brushKey)
    {
        var panel = new DockPanel { Margin = new Thickness(8, 6, 8, 6), LastChildFill = true };
        panel.Children.Add(CreateAccentIcon(mdl2Icon, brushKey));

        var link = new TextBlock
        {
            TextWrapping = TextWrapping.Wrap,
            VerticalAlignment = VerticalAlignment.Center,
        };
        ContentTextDirectionHelper.ApplyTo(link, label);
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

    private static UIElement CreateAccentIcon(string mdl2Icon, string brushKey)
    {
        var icon = new TextBlock
        {
            FontFamily = new FontFamily("Segoe MDL2 Assets"),
            Text = mdl2Icon,
            FontSize = 18,
            Margin = new Thickness(0, 0, 12, 0),
            VerticalAlignment = VerticalAlignment.Center,
        };
        icon.SetResourceReference(TextBlock.ForegroundProperty, brushKey);
        DockPanel.SetDock(icon, Dock.Left);
        return icon;
    }
}
