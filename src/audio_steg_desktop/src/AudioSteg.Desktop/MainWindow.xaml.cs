using System.Windows;

namespace AudioSteg.Desktop;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        RefreshUi();
    }

    public void RefreshUi()
    {
        ThemeManager.Apply(this);
        var s = ThemeManager.Strings;
        Title = s.AppTitle;
        TitleText.Text = s.AppTitle;
        EmbedTabItem.Header = s.EmbedTab;
        ExtractTabItem.Header = s.ExtractTab;
        SettingsTabItem.Header = s.SettingsTab;

        if (EmbedTabItem.Content is Views.EmbedView ev) ev.ApplyStrings();
        if (ExtractTabItem.Content is Views.ExtractView xv) xv.ApplyStrings();
    }

    private void AboutButton_Click(object sender, RoutedEventArgs e)
    {
        var s = ThemeManager.Strings;
        MessageBox.Show(
            s.AboutAlgoBody,
            s.AboutTitle,
            MessageBoxButton.OK,
            MessageBoxImage.Information);
    }
}
