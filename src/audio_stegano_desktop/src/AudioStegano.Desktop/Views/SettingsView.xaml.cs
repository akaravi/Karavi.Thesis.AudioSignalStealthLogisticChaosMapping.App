using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using AudioStegano.Desktop.Localization;
using AudioStegano.Desktop.Services;

namespace AudioStegano.Desktop.Views;

public partial class SettingsView : UserControl
{
    private bool _loading;

    public SettingsView()
    {
        InitializeComponent();
        Loaded += (_, _) => LoadFromState();
    }

    public void ApplyStrings() => LoadFromState();

    private void LoadFromState()
    {
        _loading = true;
        var s = ThemeManager.Strings;
        ThemeLabel.Text = s.ThemeMode;
        LanguageLabel.Text = s.Language;
        LogisticLabel.Text = s.LogisticParams;
        RLabel.Text = s.RParam;
        X0Label.Text = s.X0Param;
        RRangeHint.Text = s.LogisticRRangeHint;
        X0RangeHint.Text = s.LogisticX0RangeHint;
        ResetLabel.Text = s.Reset;
        WindowsOpenWithTitle.Text = s.WindowsOpenWithTitle;
        WindowsOpenWithHint.Text = s.WindowsOpenWithHint;
        RegisterOpenWithCheck.Content = s.WindowsOpenWithTitle;
        RegisterOpenWithCheck.IsChecked = AppState.Settings.RegisterWindowsFileAssociations;
        WindowsOpenWithCard.Visibility = OperatingSystem.IsWindows()
            ? Visibility.Visible
            : Visibility.Collapsed;

        if (AppState.Settings.ThemeMode == AppThemeMode.System)
        {
            AppState.Settings.ThemeMode = AppThemeMode.Light;
            AppState.Save();
        }

        BuildThemeSegments(s);
        BuildLanguageSegments(s);

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

    private void RegisterOpenWithCheck_Changed(object sender, RoutedEventArgs e)
    {
        if (_loading || !IsLoaded || !OperatingSystem.IsWindows()) return;

        var enable = RegisterOpenWithCheck.IsChecked == true;
        AppState.Settings.RegisterWindowsFileAssociations = enable;
        AppState.Settings.WindowsOpenWithOfferSeen = true;
        AppState.Save();

        var exe = Environment.ProcessPath;
        if (string.IsNullOrEmpty(exe)) return;

        var s = ThemeManager.Strings;
        if (enable)
        {
            try
            {
                WindowsFileAssociationService.Register(exe, s.AppTitle);
                StatusToast(s.WindowsOpenWithRegistered);
            }
            catch (Exception ex)
            {
                RegisterOpenWithCheck.IsChecked = false;
                AppState.Settings.RegisterWindowsFileAssociations = false;
                AppState.Save();
                MessageBox.Show(
                    $"{s.WindowsOpenWithRegisterFailed}\n\n{ex.Message}",
                    s.SettingsTab,
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);
            }
        }
        else
        {
            WindowsFileAssociationService.Unregister();
            StatusToast(s.WindowsOpenWithUnregistered);
        }
    }

    private void StatusToast(string message)
    {
        MessageBox.Show(message, ThemeManager.Strings.SettingsTab, MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private void DefaultFixedMsgBitLimitCheck_Changed(object sender, RoutedEventArgs e)
    {
        if (_loading || !IsLoaded) return;
        AppState.Settings.DefaultFixedMessageBitLimit =
            DefaultFixedMsgBitLimitCheck.IsChecked == true;
        AppState.Save();
        RefreshShell();
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
        var labels = new[] { s.ThemeLight, s.ThemeDark };
        var modes = new[] { AppThemeMode.Light, AppThemeMode.Dark };
        for (var i = 0; i < 2; i++)
        {
            var mode = modes[i];
            var selected = AppState.Settings.ThemeMode == mode
                || (mode == AppThemeMode.Light && AppState.Settings.ThemeMode == AppThemeMode.System);
            var btn = CreateSegment(labels[i], selected);
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
