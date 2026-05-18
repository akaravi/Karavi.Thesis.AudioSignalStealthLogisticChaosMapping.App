using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;
using AudioSteg.Core.Stego;
using AudioSteg.Desktop.Localization;

namespace AudioSteg.Desktop.Views;

public partial class SettingsView : UserControl
{
    private static readonly string[] SeedColors =
    [
        "#6750A4", "#1B73E8", "#2E7D32", "#E65100", "#C62828", "#455A64",
    ];

    private bool _loading;

    public SettingsView()
    {
        InitializeComponent();
        Loaded += (_, _) => LoadFromState();
    }

    private void LoadFromState()
    {
        _loading = true;
        var s = ThemeManager.Strings;
        ThemeLabel.Text = s.ThemeMode;
        LanguageLabel.Text = s.Language;
        ColorSeedLabel.Text = s.ColorSeed;
        LogisticLabel.Text = s.LogisticParams;
        RLabel.Text = s.RParam;
        X0Label.Text = s.X0Param;
        ResetLabel.Text = s.Reset;

        BuildThemeSegments(s);
        BuildLanguageSegments(s);
        BuildColorSeeds();

        var st = AppState.Settings;
        RSlider.Value = st.R;
        X0Slider.Value = st.X0;
        UpdateSliderLabels();
        _loading = false;
    }

    private void BuildThemeSegments(AppStrings s)
    {
        ThemeSegments.Children.Clear();
        var labels = new[] { s.ThemeLight, s.ThemeDark, s.ThemeSystem };
        var modes = new[] { AppThemeMode.Light, AppThemeMode.Dark, AppThemeMode.System };
        for (var i = 0; i < 3; i++)
        {
            var mode = modes[i];
            var btn = CreateSegment(labels[i], AppState.Settings.ThemeMode == mode);
            var captured = mode;
            btn.Click += (_, _) =>
            {
                AppState.Settings.ThemeMode = captured;
                AppState.Save();
                RefreshShell();
            };
            ThemeSegments.Children.Add(btn);
        }
    }

    private void BuildLanguageSegments(AppStrings s)
    {
        LanguageSegments.Children.Clear();
        var faBtn = CreateSegment(s.Persian, AppState.Settings.Language == AppLanguage.Fa);
        faBtn.Click += (_, _) =>
        {
            AppState.Settings.Language = AppLanguage.Fa;
            AppState.Save();
            RefreshShell();
        };
        var enBtn = CreateSegment(s.English, AppState.Settings.Language == AppLanguage.En);
        enBtn.Click += (_, _) =>
        {
            AppState.Settings.Language = AppLanguage.En;
            AppState.Save();
            RefreshShell();
        };
        LanguageSegments.Children.Add(faBtn);
        LanguageSegments.Children.Add(enBtn);
    }

    private void BuildColorSeeds()
    {
        ColorSeedPanel.Children.Clear();
        var current = AppState.Settings.AccentColor.ToUpperInvariant();
        foreach (var hex in SeedColors)
        {
            var color = (Color)ColorConverter.ConvertFromString(hex)!;
            var ring = current == hex.ToUpperInvariant();
            var btn = new Button
            {
                Width = 44,
                Height = 44,
                Margin = new Thickness(0, 0, 12, 12),
                Background = Brushes.Transparent,
                BorderThickness = new Thickness(0),
                Cursor = System.Windows.Input.Cursors.Hand,
                Tag = hex,
            };
            var ellipse = new Ellipse
            {
                Width = 36,
                Height = 36,
                Fill = new SolidColorBrush(color),
                Stroke = ring ? (Brush)FindResource("TextBrush") : null,
                StrokeThickness = ring ? 3 : 0,
            };
            btn.Content = ellipse;
            btn.Click += (_, _) =>
            {
                AppState.Settings.AccentColor = hex;
                AppState.Save();
                RefreshShell();
            };
            ColorSeedPanel.Children.Add(btn);
        }
    }

    private static Button CreateSegment(string label, bool selected) =>
        new()
        {
            Content = label,
            Margin = new Thickness(4, 0, 4, 0),
            Padding = new Thickness(12, 8, 12, 8),
            Background = selected
                ? (Brush)Application.Current.Resources["NavIndicatorBrush"]
                : Brushes.Transparent,
            Foreground = (Brush)Application.Current.Resources["TextBrush"],
            BorderThickness = new Thickness(0),
            Cursor = System.Windows.Input.Cursors.Hand,
        };

    private void UpdateSliderLabels()
    {
        if (RValueText is null || X0ValueText is null) return;
        RValueText.Text = RSlider.Value.ToString("F3");
        X0ValueText.Text = X0Slider.Value.ToString("F2");
    }

    private void RSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading || !IsLoaded) return;
        AppState.Settings.R = RSlider.Value;
        AppState.Save();
        UpdateSliderLabels();
    }

    private void X0Slider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading || !IsLoaded) return;
        AppState.Settings.X0 = X0Slider.Value;
        AppState.Save();
        UpdateSliderLabels();
    }

    private void ResetButton_Click(object sender, RoutedEventArgs e)
    {
        AppState.ResetToDefaults();
        AppState.Save();
        LoadFromState();
        RefreshShell();
    }

    private static void RefreshShell()
    {
        ThemeManager.Apply(Application.Current.Resources);
        if (Application.Current.MainWindow is MainWindow mw)
            mw.RefreshUi();
    }
}
