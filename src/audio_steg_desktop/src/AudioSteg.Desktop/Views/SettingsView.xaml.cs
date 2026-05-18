using System.Linq;
using System.Windows;
using System.Windows.Controls;
using AudioSteg.Core.Stego;

namespace AudioSteg.Desktop.Views;

public partial class SettingsView : UserControl
{
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
        LogisticLabel.Text = s.LogisticParams;
        RLabel.Text = s.RParam;
        X0Label.Text = s.X0Param;
        ResetButton.Content = s.Reset;

        ThemeCombo.Items.Clear();
        ThemeCombo.Items.Add(s.ThemeLight);
        ThemeCombo.Items.Add(s.ThemeDark);
        ThemeCombo.Items.Add(s.ThemeSystem);

        LanguageCombo.Items.Clear();
        LanguageCombo.Items.Add(s.Persian);
        LanguageCombo.Items.Add(s.English);

        var st = AppState.Settings;
        ThemeCombo.SelectedIndex = st.ThemeMode switch
        {
            AppThemeMode.Light => 0,
            AppThemeMode.Dark => 1,
            _ => 2,
        };
        LanguageCombo.SelectedIndex = st.Language == AppLanguage.Fa ? 0 : 1;
        RSlider.Value = st.R;
        X0Slider.Value = st.X0;
        UpdateSliderLabels();
        _loading = false;
    }

    private void UpdateSliderLabels()
    {
        RValueText.Text = RSlider.Value.ToString("F3");
        X0ValueText.Text = X0Slider.Value.ToString("F2");
    }

    private void ThemeCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading || ThemeCombo.SelectedIndex < 0) return;
        AppState.Settings.ThemeMode = ThemeCombo.SelectedIndex switch
        {
            0 => AppThemeMode.Light,
            1 => AppThemeMode.Dark,
            _ => AppThemeMode.System,
        };
        AppState.Save();
        RefreshShell();
    }

    private void LanguageCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading || LanguageCombo.SelectedIndex < 0) return;
        AppState.Settings.Language = LanguageCombo.SelectedIndex == 0
            ? AppLanguage.Fa
            : AppLanguage.En;
        AppState.Save();
        LoadFromState();
        RefreshShell();
    }

    private void RSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
        AppState.Settings.R = RSlider.Value;
        AppState.Save();
        UpdateSliderLabels();
    }

    private void X0Slider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
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
        if (Window.GetWindow(Application.Current.MainWindow) is MainWindow mw)
            mw.RefreshUi();
        foreach (var w in Application.Current.Windows.OfType<MainWindow>())
            w.RefreshUi();
    }
}
