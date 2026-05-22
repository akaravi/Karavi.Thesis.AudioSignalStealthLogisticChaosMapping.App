using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using AudioStegano.Core.Audio;
using AudioStegano.Core.Stego;
using AudioStegano.Desktop.Services;
using Microsoft.Win32;

namespace AudioStegano.Desktop.Views;

public partial class ExtractView : UserControl
{
    private readonly AudioPlaybackService _playback = new();
    private WavFile? _loadedWav;

    public ExtractView()
    {
        InitializeComponent();
        _playback.PlaybackStateChanged += UpdatePlaybackButtons;
        Loaded += (_, _) => ApplyStrings();
    }

    public void ApplyStrings()
    {
        var s = ThemeManager.Strings;
        PickTitle.Text = s.PickFile;
        BitLengthBox.SetValue(ToolTipService.ToolTipProperty, s.MsgBitLengthHint);
        BitLengthHelper.Text = s.MsgBitLengthHelper;
        PickLabel.Text = s.PickFile;
        ExtractLabel.Text = s.ExtractTab;
        ResultTitle.Text = s.ExtractedText;
        CopyLabel.Text = s.Copy;
        ToolTipService.SetToolTip(PlayButton, s.Play);
        ToolTipService.SetToolTip(PauseButton, s.Pause);
        ToolTipService.SetToolTip(StopPlaybackButton, s.StopPlayback);
        ApplyBitLengthPanelVisibility();
    }

    private void ApplyBitLengthPanelVisibility()
    {
        var hide = AppState.Settings.DefaultFixedMessageBitLimit;
        BitLengthPanel.Visibility = hide ? Visibility.Collapsed : Visibility.Visible;
    }

    private void UpdatePlaybackButtons()
    {
        if (!Dispatcher.CheckAccess())
        {
            Dispatcher.BeginInvoke(UpdatePlaybackButtons);
            return;
        }

        var playing = _playback.IsPlaying;
        var hasSource = _playback.HasSource;
        var paused = _playback.IsPaused;
        PlayButton.IsEnabled = !playing && _loadedWav is not null;
        PauseButton.IsEnabled = playing;
        StopPlaybackButton.IsEnabled = hasSource && (playing || paused);
    }

    private int? ParseBitLength()
    {
        var s = ThemeManager.Strings;
        var raw = BitLengthBox.Text.Trim();
        if (string.IsNullOrEmpty(raw))
        {
            StatusText.Text = s.ErrorBitLengthEmpty;
            return null;
        }

        if (!int.TryParse(raw, out var n) || n <= 0)
        {
            StatusText.Text = s.ErrorBitLengthInvalid;
            return null;
        }

        return n;
    }

    private void SetBusy(bool busy)
    {
        BusyBar.Visibility = busy ? Visibility.Visible : Visibility.Collapsed;
        PickButton.IsEnabled = !busy;
        ExtractButton.IsEnabled = !busy && _loadedWav is not null;
    }

    private async void PickButton_Click(object sender, RoutedEventArgs e)
    {
        var s = ThemeManager.Strings;
        var dlg = new OpenFileDialog { Filter = AudioInputLoader.OpenDialogFilter };
        if (dlg.ShowDialog() != true) return;

        SetBusy(true);
        StatusText.Text = s.Processing;
        ResultPanel.Visibility = Visibility.Collapsed;

        WavFile? wav = null;
        string? error = null;
        await Task.Run(() =>
        {
            try
            {
                wav = AudioInputLoader.LoadFromPath(dlg.FileName);
            }
            catch (Exception ex)
            {
                error = ex.Message;
            }
        });

        _playback.Stop();
        _loadedWav = wav;
        PlaybackPanel.Visibility = wav is not null ? Visibility.Visible : Visibility.Collapsed;
        SetBusy(false);
        UpdatePlaybackButtons();

        if (error is not null)
        {
            StatusText.Text = error;
            ExtractButton.IsEnabled = false;
            return;
        }

        if (wav is null)
        {
            StatusText.Text = s.KeyMismatch;
            ExtractButton.IsEnabled = false;
            return;
        }

        StatusText.Text = s.AudioFileLoaded(Path.GetFileName(dlg.FileName));
        ExtractButton.IsEnabled = true;
    }

    private async void ExtractButton_Click(object sender, RoutedEventArgs e)
    {
        int? bitLen;
        if (AppState.Settings.DefaultFixedMessageBitLimit)
            bitLen = AppConfig.Current.DefaultFixedMessageBitLength;
        else
        {
            bitLen = ParseBitLength();
            if (bitLen is null) return;
        }

        var s = ThemeManager.Strings;
        if (_loadedWav is null)
        {
            StatusText.Text = s.ErrorNoAudioLoaded;
            return;
        }

        SetBusy(true);
        StatusText.Text = s.Processing;
        ResultPanel.Visibility = Visibility.Collapsed;

        string? text = null;
        string? error = null;
        var wav = _loadedWav;
        await Task.Run(() =>
        {
            try
            {
                text = AppState.Watermarking.Extract(wav!, bitLen.Value);
            }
            catch (Exception ex)
            {
                error = ex.Message;
            }
        });

        SetBusy(false);

        if (error is not null)
        {
            StatusText.Text = error;
            return;
        }

        if (text is null)
        {
            StatusText.Text = s.KeyMismatch;
            ResultText.Text = s.NoText;
            ResultHeaderIcon.Text = "\uE783";
            ResultPanel.Style = (Style)FindResource("MaterialCard");
            ResultPanel.Background = (Brush)FindResource("ErrorContainerBrush");
            ResultTitle.Foreground = (Brush)FindResource("OnErrorContainerBrush");
            ResultText.Foreground = (Brush)FindResource("OnErrorContainerBrush");
            ResultPanel.Visibility = Visibility.Visible;
            return;
        }

        StatusText.Text = string.Empty;
        ResultText.Text = text;
        ResultHeaderIcon.Text = "\uE73E";
        ResultPanel.Style = (Style)FindResource("ResultCard");
        ResultTitle.Foreground = (Brush)FindResource("TextBrush");
        ResultText.Foreground = (Brush)FindResource("TextBrush");
        ResultPanel.Visibility = Visibility.Visible;
    }

    private void PlayButton_Click(object sender, RoutedEventArgs e)
    {
        if (_loadedWav is null) return;

        if (_playback.HasSource && !_playback.IsPlaying)
            _playback.Resume();
        else
            _playback.Play(_loadedWav);
    }

    private void PauseButton_Click(object sender, RoutedEventArgs e) => _playback.Pause();

    private void StopPlaybackButton_Click(object sender, RoutedEventArgs e) => _playback.Stop();

    private void CopyButton_Click(object sender, RoutedEventArgs e)
    {
        if (!string.IsNullOrEmpty(ResultText.Text))
            Clipboard.SetText(ResultText.Text);
        StatusText.Text = ThemeManager.Strings.Copied;
    }
}
