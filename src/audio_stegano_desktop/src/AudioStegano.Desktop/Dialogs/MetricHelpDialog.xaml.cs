using System.Windows;
using AudioStegano.Desktop.Models;

namespace AudioStegano.Desktop.Dialogs;

public partial class MetricHelpDialog : Window
{
    public MetricHelpDialog(EmbedMetricKind kind)
    {
        InitializeComponent();
        var s = ThemeManager.Strings;
        Title = s.MetricHelpTitle(kind);
        TitleText.Text = s.MetricHelpTitle(kind);
        BodyText.Text = s.MetricHelpBody(kind);
        OkButton.Content = s.HelpClose;
    }

    private void OkButton_Click(object sender, RoutedEventArgs e) => DialogResult = true;
}
