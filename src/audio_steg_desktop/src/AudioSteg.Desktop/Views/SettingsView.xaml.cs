using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using AudioSteg.Desktop.Localization;

namespace AudioSteg.Desktop.Views;

public partial class SettingsView : UserControl
{
    private static readonly string[] SeedColors =
    [
        "#00B4B7", "#1B73E8", "#2E7D32", "#E65100", "#C62828", "#455A64",
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
        RRangeHint.Text = s.LogisticRRangeHint;
        X0RangeHint.Text = s.LogisticX0RangeHint;
        ResetLabel.Text = s.Reset;

        BuildThemeSegments(s);
        BuildLanguageSegments(s);
        BuildColorSeeds();

        var st = AppState.Settings;
        RSlider.Value = LogisticParamBounds.ClampR(st.R);
        X0Slider.Value = LogisticParamBounds.ClampX0(st.X0);
        SyncParamTextBoxes();
        SyncLogisticPreview(s);
        var fixedBits = AppConfig.Current.DefaultFixedMessageBitLength;
        DefaultFixedMsgBitLimitCheck.Content = s.DefaultFixedMessageBitLimit(fixedBits);
        DefaultFixedMsgBitLimitCheck.ToolTip = s.DefaultFixedMessageBitLimitHint(fixedBits);
        DefaultFixedMsgBitLimitCheck.IsChecked = st.DefaultFixedMessageBitLimit;
        _loading = false;
    }

    private void DefaultFixedMsgBitLimitCheck_Changed(object sender, RoutedEventArgs e)
    {
        if (_loading || !IsLoaded) return;
        AppState.Settings.DefaultFixedMessageBitLimit =
            DefaultFixedMsgBitLimitCheck.IsChecked == true;
        AppState.Save();
    }

    private void SyncLogisticPreview(AppStrings s)
    {
        LogisticPreview.SetCaption(s.LogisticMapPreviewHint);
        LogisticPreview.R = RSlider.Value;
        LogisticPreview.X0 = X0Slider.Value;
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
        AddLanguageButton(s.Persian, AppLanguage.Fa);
        AddLanguageButton(s.English, AppLanguage.En);
        AddLanguageButton(s.Arabic, AppLanguage.Ar);
        AddLanguageButton(s.French, AppLanguage.Fr);
    }

    private void AddLanguageButton(string label, AppLanguage lang)
    {
        var btn = CreateSegment(label, AppState.Settings.Language == lang);
        btn.Click += (_, _) =>
        {
            AppState.Settings.Language = lang;
            AppState.Save();
            RefreshShell();
        };
        LanguageSegments.Children.Add(btn);
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
                Width = 36,
                Height = 36,
                Margin = new Thickness(0, 0, 8, 8),
                Background = Brushes.Transparent,
                BorderThickness = new Thickness(0),
                Cursor = System.Windows.Input.Cursors.Hand,
                Tag = hex,
            };
            var ellipse = new Ellipse
            {
                Width = 28,
                Height = 28,
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
            Padding = new Thickness(10, 6, 10, 6),
            Background = selected
                ? (Brush)Application.Current.Resources["NavIndicatorBrush"]
                : Brushes.Transparent,
            Foreground = (Brush)Application.Current.Resources["TextBrush"],
            BorderThickness = new Thickness(0),
            Cursor = System.Windows.Input.Cursors.Hand,
        };

    private void SyncParamTextBoxes()
    {
        RTextBox.Text = RSlider.Value.ToString("F3", CultureInfo.InvariantCulture);
        X0TextBox.Text = X0Slider.Value.ToString("F2", CultureInfo.InvariantCulture);
    }

    private void RSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading || !IsLoaded) return;
        AppState.Settings.R = LogisticParamBounds.ClampR(RSlider.Value);
        AppState.Save();
        SyncParamTextBoxes();
        SyncLogisticPreview(ThemeManager.Strings);
    }

    private void X0Slider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading || !IsLoaded) return;
        AppState.Settings.X0 = LogisticParamBounds.ClampX0(X0Slider.Value);
        AppState.Save();
        SyncParamTextBoxes();
        SyncLogisticPreview(ThemeManager.Strings);
    }

    private void RTextBox_LostFocus(object sender, RoutedEventArgs e) => CommitRFromTextBox();

    private void X0TextBox_LostFocus(object sender, RoutedEventArgs e) => CommitX0FromTextBox();

    private void ParamTextBox_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key != Key.Enter) return;
        if (sender == RTextBox) CommitRFromTextBox();
        else if (sender == X0TextBox) CommitX0FromTextBox();
        e.Handled = true;
    }

    private void CommitRFromTextBox()
    {
        if (_loading) return;
        if (!LogisticParamBounds.TryParseR(RTextBox.Text, out var r))
        {
            MessageBox.Show(
                ThemeManager.Strings.LogisticInvalidValue,
                ThemeManager.Strings.AppTitle,
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            SyncParamTextBoxes();
            return;
        }

        _loading = true;
        RSlider.Value = r;
        AppState.Settings.R = r;
        AppState.Save();
        SyncParamTextBoxes();
        SyncLogisticPreview(ThemeManager.Strings);
        _loading = false;
    }

    private void CommitX0FromTextBox()
    {
        if (_loading) return;
        if (!LogisticParamBounds.TryParseX0(X0TextBox.Text, out var x0))
        {
            MessageBox.Show(
                ThemeManager.Strings.LogisticInvalidValue,
                ThemeManager.Strings.AppTitle,
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            SyncParamTextBoxes();
            return;
        }

        _loading = true;
        X0Slider.Value = x0;
        AppState.Settings.X0 = x0;
        AppState.Save();
        SyncParamTextBoxes();
        SyncLogisticPreview(ThemeManager.Strings);
        _loading = false;
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
