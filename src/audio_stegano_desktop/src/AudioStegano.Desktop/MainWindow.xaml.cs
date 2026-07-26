using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using AudioStegano.Desktop.Services;
using AudioStegano.Desktop.Views;

namespace AudioStegano.Desktop;

public partial class MainWindow : Window
{
    private const int TabCount = 4;
    private readonly RadioButton[] _navButtons = new RadioButton[TabCount];
    private int _selectedIndex;

    public MainWindow()
    {
        InitializeComponent();
        SizeChanged += (_, _) => UpdateWideLayout();
        RefreshUi();
        BuildNavigation();
        SelectTab(0);
        Loaded += MainWindow_Loaded;
    }

    private void MainWindow_Loaded(object sender, RoutedEventArgs e)
    {
        OpenPendingAudioFile();
        WindowsOpenWithPrompt.OfferIfNeeded();
    }

    public void OpenPendingAudioFile()
    {
        var path = AppState.PendingOpenAudioPath;
        if (string.IsNullOrEmpty(path)) return;
        AppState.PendingOpenAudioPath = null;
        Activate();
        SelectTab(1);
        ExtractPage.LoadAudioFromPath(path);
    }

    public void RefreshUi()
    {
        ThemeManager.Apply(this);
        ThemeManager.Apply(Resources);
        var s = ThemeManager.Strings;
        Title = s.AppTitle;
        TitleText.Text = s.AppTitle;

        UpdateNavLabels();
        EmbedPage.ApplyStrings();
        EmbedPage.UpdateMessageBitCounter();
        ExtractPage.ApplyStrings();
        SettingsPage.ApplyStrings();
        AboutPage.ApplyStrings();
    }

    private void BuildNavigation()
    {
        BottomNavGrid.Children.Clear();
        RailButtons.Children.Clear();

        var icons = new[] { "\uE9D8", "\uE721", "\uE713", "\uE77B" };
        for (var i = 0; i < TabCount; i++)
        {
            var idx = i;
            var btn = CreateNavButton(icons[i], i, "BottomNav");
            btn.Checked += (_, _) => { if (btn.IsChecked == true) SelectTab(idx); };
            _navButtons[i] = btn;
            BottomNavGrid.Children.Add(btn);

            var railBtn = CreateNavButton(icons[i], i, "RailNav");
            railBtn.Checked += (_, _) => { if (railBtn.IsChecked == true) SelectTab(idx); };
            RailButtons.Children.Add(railBtn);
        }
    }

    private RadioButton CreateNavButton(string icon, int index, string groupName)
    {
        var s = ThemeManager.Strings;
        var labels = new[] { s.EmbedTab, s.ExtractTab, s.SettingsTab, s.AboutUsTab };
        return new RadioButton
        {
            Style = (Style)FindResource("NavTabButton"),
            Tag = labels[index],
            GroupName = groupName,
            Content = new TextBlock
            {
                FontFamily = new FontFamily("Segoe MDL2 Assets"),
                FontSize = 22,
                Text = icon,
                HorizontalAlignment = HorizontalAlignment.Center,
            },
        };
    }

    private void UpdateNavLabels()
    {
        var s = ThemeManager.Strings;
        var labels = new[] { s.EmbedTab, s.ExtractTab, s.SettingsTab, s.AboutUsTab };
        for (var i = 0; i < _navButtons.Length && i < BottomNavGrid.Children.Count; i++)
        {
            if (BottomNavGrid.Children[i] is RadioButton rb)
                rb.Tag = labels[i];
        }
    }

    private void SelectTab(int index)
    {
        if (index != _selectedIndex)
        {
            if (_selectedIndex == 0)
                PlaybackHub.Instance.StopSessions(PlaybackHub.EmbedSessions);
            else if (_selectedIndex == 1)
                PlaybackHub.Instance.StopSessions(PlaybackHub.ExtractSessions);
        }

        _selectedIndex = index;
        EmbedPage.Visibility = index == 0 ? Visibility.Visible : Visibility.Collapsed;
        ExtractPage.Visibility = index == 1 ? Visibility.Visible : Visibility.Collapsed;
        SettingsPage.Visibility = index == 2 ? Visibility.Visible : Visibility.Collapsed;
        AboutPage.Visibility = index == 3 ? Visibility.Visible : Visibility.Collapsed;

        for (var i = 0; i < _navButtons.Length; i++)
            _navButtons[i].IsChecked = i == index;

        var railIndex = 0;
        foreach (var child in RailButtons.Children)
        {
            if (child is RadioButton rb)
                rb.IsChecked = railIndex++ == index;
        }
    }

    private void UpdateWideLayout()
    {
        var wide = ActualWidth >= 720;
        NavRail.Visibility = wide ? Visibility.Visible : Visibility.Collapsed;
        BottomNav.Visibility = wide ? Visibility.Collapsed : Visibility.Visible;
        RailColumn.Width = wide ? new GridLength(88) : new GridLength(0);
    }
}
