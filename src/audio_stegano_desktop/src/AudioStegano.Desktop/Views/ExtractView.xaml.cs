using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using AudioStegano.Core.Audio;
using AudioStegano.Core.Stego;
using AudioStegano.Desktop.Dialogs;
using AudioStegano.Desktop.Localization;
using AudioStegano.Desktop.Services;
using Microsoft.Win32;

namespace AudioStegano.Desktop.Views;

public partial class ExtractView : UserControl
{
    private readonly PlaybackHub _hub = PlaybackHub.Instance;
    private WavFile? _loadedWav;
    private WavFile? _extractedAudio;
    private byte[]? _extractedImageBytes;

    public ExtractView()
    {
        InitializeComponent();
        _hub.Engine(PlaybackSessionId.ExtractCover).PlaybackStateChanged += UpdatePlaybackButtons;
        _hub.Engine(PlaybackSessionId.ExtractPayload).PlaybackStateChanged += UpdateExtractedPlayButton;
        Loaded += (_, _) =>
        {
            ApplyStrings();
            AudioFileDropHelper.Enable(ExtractCard, OnAudioFileDroppedAsync);
        };
    }

    private Task OnAudioFileDroppedAsync(string path) => LoadAudioFromPathAsync(path);

    private async Task LoadAudioFromPathAsync(string filePath)
    {
        if (string.IsNullOrWhiteSpace(filePath) || !File.Exists(filePath)) return;

        var s = ThemeManager.Strings;
        SetBusy(true);
        StatusText.Text = s.Processing;
        ExtractCard.Visibility = Visibility.Visible;
        ResultPanel.Visibility = Visibility.Collapsed;

        WavFile? wav = null;
        string? error = null;
        await Task.Run(() =>
        {
            try
            {
                wav = AudioInputLoader.LoadFromPath(filePath);
            }
            catch (Exception ex)
            {
                error = AudioLoadErrors.Format(ThemeManager.Strings, ex);
            }
        });

        _hub.StopSessions(PlaybackHub.ExtractSessions);
        _loadedWav = wav;
        PlaybackPanel.Visibility = wav is not null ? Visibility.Visible : Visibility.Collapsed;
        SetBusy(false);

        if (error is not null)
        {
            StatusText.Text = error;
            ExtractButton.IsEnabled = false;
        }
        else if (wav is null)
        {
            StatusText.Text = s.KeyMismatch;
            ExtractButton.IsEnabled = false;
        }
        else
        {
            StatusText.Text = s.AudioFileLoaded(Path.GetFileName(filePath));
            ExtractButton.IsEnabled = true;
        }

        UpdatePlaybackButtons();
        UpdateFabStates();
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
        PlayExtractedLabel.Text = s.PlayExtractedAudio;
        SaveExtractedLabel.Text = s.SaveExtractedAudio;
        ToolTipService.SetToolTip(PlayButton, s.Play);
        ToolTipService.SetToolTip(PauseButton, s.Pause);
        ToolTipService.SetToolTip(StopPlaybackButton, s.StopPlayback);
        ToolTipService.SetToolTip(NewExtractFab, s.ExtractNew);
        ToolTipService.SetToolTip(HelpFab, s.HelpTooltip);
        ApplyBitLengthPanelVisibility();
        UpdateFabStates();
    }

    private void UpdateFabStates()
    {
        var busy = BusyBar.Visibility == Visibility.Visible;
        NewExtractFab.IsEnabled = !busy;
    }

    private void HelpFab_Click(object sender, RoutedEventArgs e)
    {
        var owner = Window.GetWindow(this);
        var dlg = new HelpDialog(HelpSection.Extract);
        if (owner is not null)
            dlg.Owner = owner;
        dlg.ShowDialog();
    }

    private void NewExtractFab_Click(object sender, RoutedEventArgs e)
    {
        if (BusyBar.Visibility == Visibility.Visible) return;
        _hub.StopSessions(PlaybackHub.ExtractSessions);
        _loadedWav = null;
        _extractedAudio = null;
        ClearExtractedImage();
        BitLengthBox.Clear();
        ExtractCard.Visibility = Visibility.Visible;
        ResultPanel.Visibility = Visibility.Collapsed;
        PlaybackPanel.Visibility = Visibility.Collapsed;
        StatusText.Text = string.Empty;
        ExtractButton.IsEnabled = false;
        UpdatePlaybackButtons();
        UpdateFabStates();
        MainScroll.ScrollToHome();
    }

    public void LoadAudioFromPath(string filePath) =>
        _ = LoadAudioFromPathAsync(filePath);

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

        var playing = _hub.IsPlaying(PlaybackSessionId.ExtractCover);
        var hasSource = _hub.HasSource(PlaybackSessionId.ExtractCover);
        var paused = _hub.IsPaused(PlaybackSessionId.ExtractCover);
        PlayButton.IsEnabled = !playing && _loadedWav is not null;
        PauseButton.IsEnabled = playing;
        StopPlaybackButton.IsEnabled = hasSource && (playing || paused);
        UpdateExtractedPlayButton();
    }

    private void UpdateExtractedPlayButton()
    {
        if (!Dispatcher.CheckAccess())
        {
            Dispatcher.BeginInvoke(UpdateExtractedPlayButton);
            return;
        }

        if (PlayExtractedButton.Visibility != Visibility.Visible)
            return;

        var s = ThemeManager.Strings;
        if (_hub.IsPlaying(PlaybackSessionId.ExtractPayload))
        {
            PlayExtractedLabel.Text = s.Pause;
            PlayExtractedButton.IsEnabled = true;
        }
        else
        {
            PlayExtractedLabel.Text = s.PlayExtractedAudio;
            PlayExtractedButton.IsEnabled = _extractedAudio is not null;
        }
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
        UpdateFabStates();
    }

    private async void PickButton_Click(object sender, RoutedEventArgs e)
    {
        var dlg = new OpenFileDialog { Filter = AudioInputLoader.OpenDialogFilter };
        if (dlg.ShowDialog() != true) return;
        await LoadAudioFromPathAsync(dlg.FileName);
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
        ExtractCard.Visibility = Visibility.Visible;
        ResultPanel.Visibility = Visibility.Collapsed;
        _hub.Stop(PlaybackSessionId.ExtractPayload);
        _extractedAudio = null;
        ClearExtractedImage();

        StegoPayloadResult? payload = null;
        string? error = null;
        var wav = _loadedWav;
        await Task.Run(() =>
        {
            try
            {
                payload = AppState.Watermarking.ExtractPayload(wav!, bitLen.Value);
            }
            catch (Exception ex)
            {
                error = ex.Message;
            }
        });

        SetBusy(false);

        if (error is not null)
        {
            SessionLog.Write("Extract: failed", new InvalidOperationException(error));
            StatusText.Text = error;
            return;
        }

        if (payload is null)
        {
            SessionLog.Write("Extract: key mismatch or empty");
            StatusText.Text = s.KeyMismatch;
            ShowExtractFailure(s.NoText);
            return;
        }

        if (payload.ImageBytes is not null)
        {
            _extractedAudio = null;
            _extractedImageBytes = payload.ImageBytes;
            StatusText.Text = string.Empty;
            ResultText.Visibility = Visibility.Collapsed;
            ResultText.Text = string.Empty;
            ShowExtractedImage(payload.ImageBytes);
            ResultTitle.Text = s.ExtractedImage;
            ResultHeaderIcon.Text = "\uE73E";
            ResultPanel.Style = (Style)FindResource("ResultCard");
            ResultTitle.Foreground = (Brush)FindResource("TextBrush");
            CopyButton.Visibility = Visibility.Collapsed;
            PlayExtractedButton.Visibility = Visibility.Collapsed;
            SaveExtractedButton.Visibility = Visibility.Visible;
            SaveExtractedLabel.Text = s.SaveExtractedImage;
            ResultPanel.Visibility = Visibility.Visible;
            OnExtractSucceeded();
            SessionLog.Write($"Extract: image bytes={payload.ImageBytes.Length}");
            return;
        }

        if (payload.Audio is not null)
        {
            _extractedAudio = payload.Audio;
            ClearExtractedImage();
            StatusText.Text = string.Empty;
            ResultText.Visibility = Visibility.Visible;
            ResultText.Text = s.ExtractedAudio;
            ResultTitle.Text = s.ExtractedAudio;
            ContentTextDirectionHelper.ApplyTo(ResultText, ResultText.Text, forceLatinLtr: true);
            ResultHeaderIcon.Text = "\uE73E";
            ResultPanel.Style = (Style)FindResource("ResultCard");
            ResultTitle.Foreground = (Brush)FindResource("TextBrush");
            ResultText.Foreground = (Brush)FindResource("TextBrush");
            CopyButton.Visibility = Visibility.Collapsed;
            PlayExtractedButton.Visibility = Visibility.Visible;
            SaveExtractedButton.Visibility = Visibility.Visible;
            SaveExtractedLabel.Text = s.SaveExtractedAudio;
            ResultPanel.Visibility = Visibility.Visible;
            OnExtractSucceeded();
            SessionLog.Write($"Extract: audio samples={payload.Audio.Samples.Length}");
            return;
        }

        if (payload.RawBody is not null && payload.Text is null)
        {
            StatusText.Text = s.ExtractUnsupportedType;
            ShowExtractFailure(s.ExtractUnsupportedType);
            return;
        }

        if (payload.Text is null)
        {
            SessionLog.Write("Extract: key mismatch or empty");
            StatusText.Text = s.KeyMismatch;
            ShowExtractFailure(s.NoText);
            return;
        }

        _extractedAudio = null;
        ClearExtractedImage();
        StatusText.Text = string.Empty;
        ResultText.Visibility = Visibility.Visible;
        ResultText.Text = payload.Text;
        ResultTitle.Text = s.ExtractedText;
        ContentTextDirectionHelper.ApplyTo(ResultText, payload.Text);
        ResultHeaderIcon.Text = "\uE73E";
        ResultPanel.Style = (Style)FindResource("ResultCard");
        ResultTitle.Foreground = (Brush)FindResource("TextBrush");
        ResultText.Foreground = (Brush)FindResource("TextBrush");
        CopyButton.Visibility = Visibility.Visible;
        PlayExtractedButton.Visibility = Visibility.Collapsed;
        SaveExtractedButton.Visibility = Visibility.Collapsed;
        ResultPanel.Visibility = Visibility.Visible;
        OnExtractSucceeded();
        SessionLog.Write($"Extract: success length={payload.Text.Length}");
    }

    private void OnExtractSucceeded()
    {
        ExtractCard.Visibility = Visibility.Collapsed;
        ShowExtractCompleteDialog();
        ScrollResultIntoView();
    }

    private void ShowExtractCompleteDialog()
    {
        var owner = Window.GetWindow(this);
        var s = ThemeManager.Strings;
        MessageBox.Show(
            owner,
            s.OperationSuccess,
            s.ExtractCompleteTitle,
            MessageBoxButton.OK,
            MessageBoxImage.Information);
    }

    private void ScrollResultIntoView()
    {
        Dispatcher.BeginInvoke(() =>
        {
            ResultPanel.BringIntoView();
        }, System.Windows.Threading.DispatcherPriority.Loaded);
    }

    private void ClearExtractedImage()
    {
        _extractedImageBytes = null;
        ResultImage.Source = null;
        ResultImage.Visibility = Visibility.Collapsed;
    }

    private void ShowExtractedImage(byte[] bytes)
    {
        using var ms = new MemoryStream(bytes);
        var bmp = new System.Windows.Media.Imaging.BitmapImage();
        bmp.BeginInit();
        bmp.CacheOption = System.Windows.Media.Imaging.BitmapCacheOption.OnLoad;
        bmp.StreamSource = ms;
        bmp.EndInit();
        bmp.Freeze();
        ResultImage.Source = bmp;
        ResultImage.Visibility = Visibility.Visible;
    }

    private void ShowExtractFailure(string body)
    {
        _extractedAudio = null;
        ClearExtractedImage();
        ResultText.Visibility = Visibility.Visible;
        ResultText.Text = body;
        ContentTextDirectionHelper.ApplyTo(ResultText, ResultText.Text);
        ResultHeaderIcon.Text = "\uE783";
        ResultPanel.Style = (Style)FindResource("MaterialCard");
        ResultPanel.Background = (Brush)FindResource("ErrorContainerBrush");
        ResultTitle.Foreground = (Brush)FindResource("OnErrorContainerBrush");
        ResultText.Foreground = (Brush)FindResource("OnErrorContainerBrush");
        CopyButton.Visibility = Visibility.Collapsed;
        PlayExtractedButton.Visibility = Visibility.Collapsed;
        SaveExtractedButton.Visibility = Visibility.Collapsed;
        ResultPanel.Visibility = Visibility.Visible;
    }

    private void PlayExtractedButton_Click(object sender, RoutedEventArgs e)
    {
        if (_extractedAudio is null) return;
        try
        {
            _hub.PlayOrToggle(
                PlaybackSessionId.ExtractPayload,
                PayloadEnvelope.PrepareAudioForExport(_extractedAudio));
            UpdateExtractedPlayButton();
        }
        catch (Exception ex)
        {
            StatusText.Text = ex.Message;
        }
    }

    private void SaveExtractedButton_Click(object sender, RoutedEventArgs e)
    {
        if (_extractedImageBytes is not null)
        {
            var isPng = _extractedImageBytes.Length >= 4 &&
                        _extractedImageBytes[0] == 0x89 &&
                        _extractedImageBytes[1] == 0x50;
            var ext = isPng ? "png" : "jpg";
            var dlg = new SaveFileDialog
            {
                Filter = isPng ? "PNG (*.png)|*.png" : "JPEG (*.jpg)|*.jpg",
                FileName = $"extracted_payload.{ext}",
            };
            if (dlg.ShowDialog() != true) return;
            File.WriteAllBytes(dlg.FileName, _extractedImageBytes);
            StatusText.Text = ThemeManager.Strings.SuccessSaved;
            return;
        }

        if (_extractedAudio is null) return;
        var wavDlg = new SaveFileDialog
        {
            Filter = "WAV (*.wav)|*.wav",
            FileName = "extracted_payload.wav",
        };
        if (wavDlg.ShowDialog() != true) return;
        File.WriteAllBytes(
            wavDlg.FileName,
            PayloadEnvelope.PrepareAudioForExport(_extractedAudio).Encode());
        StatusText.Text = ThemeManager.Strings.SuccessSaved;
    }

    private void PlayButton_Click(object sender, RoutedEventArgs e)
    {
        if (_loadedWav is null) return;
        try
        {
            _hub.PlayIfNotPlaying(PlaybackSessionId.ExtractCover, _loadedWav);
            UpdateExtractedPlayButton();
        }
        catch (Exception ex)
        {
            StatusText.Text = ex.Message;
        }
    }

    private void PauseButton_Click(object sender, RoutedEventArgs e) =>
        _hub.Pause(PlaybackSessionId.ExtractCover);

    private void StopPlaybackButton_Click(object sender, RoutedEventArgs e) =>
        _hub.Stop(PlaybackSessionId.ExtractCover);

    private void CopyButton_Click(object sender, RoutedEventArgs e)
    {
        if (!string.IsNullOrEmpty(ResultText.Text))
            Clipboard.SetText(ResultText.Text);
        StatusText.Text = ThemeManager.Strings.Copied;
    }
}
