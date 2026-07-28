using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Threading;
using AudioStegano.Desktop.Localization;
using AudioStegano.Desktop.Services;

namespace AudioStegano.Desktop;

public partial class BootstrapWindow : Window
{
    private int _splashPage;
    private DispatcherTimer? _splashTimer;

    public BootstrapWindow()
    {
        InitializeComponent();
        ThemeManager.Apply(this);
        Loaded += (_, _) => ShowSplashPage();
    }

    private void ShowSplashPage()
    {
        ThemeManager.Apply(this);
        var s = ThemeManager.Strings;
        HostGrid.Children.Clear();

        var root = new Grid();
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var center = new StackPanel
        {
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(32),
        };

        var icon = new TextBlock
        {
            FontFamily = new FontFamily("Segoe MDL2 Assets"),
            FontSize = 72,
            Foreground = (Brush)FindResource("PrimaryBrush"),
            HorizontalAlignment = HorizontalAlignment.Center,
            Text = _splashPage == 0 ? "\uE189" : "\uE9D8",
        };
        center.Children.Add(icon);

        center.Children.Add(new TextBlock
        {
            Text = _splashPage == 0 ? s.SplashTitleAudio : s.SplashTitleStego,
            TextAlignment = TextAlignment.Center,
            FontSize = 22,
            FontWeight = FontWeights.SemiBold,
            Foreground = (Brush)FindResource("TextBrush"),
            Margin = new Thickness(0, 24, 0, 8),
            TextWrapping = TextWrapping.Wrap,
        });
        center.Children.Add(new TextBlock
        {
            Text = _splashPage == 0 ? s.SplashSubtitleAudio : s.SplashSubtitleStego,
            TextAlignment = TextAlignment.Center,
            Style = (Style)FindResource("BodySmall"),
            TextWrapping = TextWrapping.Wrap,
        });

        Grid.SetRow(center, 0);
        root.Children.Add(center);

        var version = new TextBlock
        {
            Text = AppVersion.Display,
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(0, 0, 0, 24),
            Foreground = (Brush)FindResource("MutedBrush"),
            FontSize = 12,
        };
        Grid.SetRow(version, 1);
        root.Children.Add(version);

        HostGrid.Children.Add(root);

        _splashTimer?.Stop();
        _splashTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(2800) };
        _splashTimer.Tick += SplashTimer_Tick;
        _splashTimer.Start();
    }

    private void SplashTimer_Tick(object? sender, EventArgs e)
    {
        _splashTimer?.Stop();
        if (_splashPage == 0)
        {
            _splashPage = 1;
            ShowSplashPage();
            return;
        }

        AdvanceAfterSplash();
    }

    private void AdvanceAfterSplash()
    {
        if (!AppState.Settings.LocaleConfigured)
        {
            ShowLanguageOnboarding();
            return;
        }

        if (!AppState.Settings.UsageGuideSeen)
        {
            ShowUsageGuide();
            return;
        }

        OpenMainAndClose();
    }

    private void ShowLanguageOnboarding()
    {
        ThemeManager.Apply(this);
        var s = ThemeManager.Strings;
        HostGrid.Children.Clear();

        var scroll = new ScrollViewer { VerticalScrollBarVisibility = ScrollBarVisibility.Auto };
        var panel = new StackPanel { Margin = new Thickness(24) };

        panel.Children.Add(new TextBlock
        {
            FontFamily = new FontFamily("Segoe MDL2 Assets"),
            Text = "\uE775",
            FontSize = 52,
            Foreground = (Brush)FindResource("PrimaryBrush"),
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(0, 16, 0, 16),
        });
        panel.Children.Add(new TextBlock
        {
            Text = s.Language,
            FontSize = 22,
            FontWeight = FontWeights.Bold,
            TextAlignment = TextAlignment.Center,
            Foreground = (Brush)FindResource("TextBrush"),
        });
        panel.Children.Add(new TextBlock
        {
            Text = s.ChooseLanguage,
            TextAlignment = TextAlignment.Center,
            Style = (Style)FindResource("BodySmall"),
            Margin = new Thickness(0, 8, 0, 24),
        });

        AddLanguageCard(panel, s.Persian, AppLanguage.Fa);
        AddLanguageCard(panel, s.English, AppLanguage.En);
        AddLanguageCard(panel, s.Arabic, AppLanguage.Ar);
        AddLanguageCard(panel, s.French, AppLanguage.Fr);

        scroll.Content = panel;
        HostGrid.Children.Add(scroll);
    }

    private void AddLanguageCard(StackPanel parent, string label, AppLanguage lang)
    {
        var btn = new Button
        {
            Content = label,
            Style = (Style)FindResource("TonalButton"),
            Margin = new Thickness(0, 0, 0, 8),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            HorizontalContentAlignment = HorizontalAlignment.Center,
        };
        btn.Click += (_, _) =>
        {
            AppState.Settings.Language = lang;
            AppState.CompleteLocaleOnboarding();
            AppState.Save();
            ThemeManager.Apply(this);
            AdvanceAfterSplash();
        };
        parent.Children.Add(btn);
    }

    private void ShowUsageGuide()
    {
        ThemeManager.Apply(this);
        var s = ThemeManager.Strings;
        HostGrid.Children.Clear();

        var grid = new Grid();
        grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var scroll = new ScrollViewer { VerticalScrollBarVisibility = ScrollBarVisibility.Auto };
        var panel = new StackPanel { Margin = new Thickness(24, 16, 24, 8) };

        panel.Children.Add(new TextBlock
        {
            FontFamily = new FontFamily("Segoe MDL2 Assets"),
            Text = "\uE736",
            FontSize = 52,
            Foreground = (Brush)FindResource("PrimaryBrush"),
            HorizontalAlignment = HorizontalAlignment.Center,
        });
        panel.Children.Add(new TextBlock
        {
            Text = s.UsageGuideTitle,
            FontSize = 22,
            FontWeight = FontWeights.Bold,
            TextAlignment = TextAlignment.Center,
            Margin = new Thickness(0, 16, 0, 16),
            Foreground = (Brush)FindResource("TextBrush"),
        });

        var purposeCard = new Border
        {
            Style = (Style)FindResource("MaterialCard"),
            Padding = new Thickness(16),
            Margin = new Thickness(0, 0, 0, 16),
            Child = new TextBlock
            {
                Text = s.UsageGuidePurpose,
                TextWrapping = TextWrapping.Wrap,
                Style = (Style)FindResource("BodySmall"),
            },
        };
        panel.Children.Add(purposeCard);

        AddGuideStep(panel, "\uE9D8", s.UsageGuideStepEmbed);
        AddGuideStep(panel, "\uE785", s.UsageGuideStepExtract);
        AddGuideStep(panel, "\uE713", s.UsageGuideStepSettings);
        AddGuideStep(panel, "\uE77B", s.UsageGuideStepAbout);

        scroll.Content = panel;
        Grid.SetRow(scroll, 0);
        grid.Children.Add(scroll);

        var continueBtn = new Button
        {
            Content = s.UsageGuideContinue,
            Style = (Style)FindResource("FilledButton"),
            Margin = new Thickness(24, 8, 24, 24),
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        continueBtn.Click += (_, _) =>
        {
            AppState.CompleteUsageGuideOnboarding();
            AppState.Save();
            WindowsOpenWithPrompt.OfferIfNeeded();
            OpenMainAndClose();
        };
        Grid.SetRow(continueBtn, 1);
        grid.Children.Add(continueBtn);

        HostGrid.Children.Add(grid);
    }

    private static void AddGuideStep(StackPanel parent, string iconGlyph, string text)
    {
        var row = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(0, 0, 0, 12) };
        var iconHost = new Border
        {
            Width = 44,
            Height = 44,
            CornerRadius = new CornerRadius(12),
            Background = (Brush)Application.Current.Resources["PrimaryContainerBrush"],
            Child = new TextBlock
            {
                FontFamily = new FontFamily("Segoe MDL2 Assets"),
                Text = iconGlyph,
                FontSize = 22,
                Foreground = (Brush)Application.Current.Resources["PrimaryBrush"],
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center,
            },
        };
        row.Children.Add(iconHost);
        row.Children.Add(new TextBlock
        {
            Text = text,
            TextWrapping = TextWrapping.Wrap,
            Margin = new Thickness(14, 4, 0, 0),
            Style = (Style)Application.Current.Resources["BodySmall"],
            VerticalAlignment = VerticalAlignment.Top,
        });
        parent.Children.Add(row);
    }

    private void OpenMainAndClose()
    {
        var main = new MainWindow();
        Application.Current.MainWindow = main;
        main.Show();
        Close();
    }
}
