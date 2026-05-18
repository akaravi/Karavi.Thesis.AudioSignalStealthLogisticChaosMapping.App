using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using AudioSteg.Core.Audio;
using AudioSteg.Core.Stego;
using AudioSteg.Desktop.Dialogs;
using AudioSteg.Desktop.Models;
using AudioSteg.Desktop.Services;
using Microsoft.Win32;

namespace AudioSteg.Desktop.Views;

public partial class EmbedView : UserControl
{
    private readonly AudioCaptureService _capture = new();
    private readonly AudioPlaybackService _playback = new();
    private double[] _eqBands = new double[SpectrumAnalyzer.BandCount];
    private WavFile? _cover;
    private WavFile? _stego;
    private WatermarkOutcome? _outcome;
    private bool _busy;

    public EmbedView()
    {
        InitializeComponent();
        _capture.SpectrumBands += OnSpectrumBands;
        _playback.SpectrumBands += OnSpectrumBands;
        _playback.PlaybackStateChanged += UpdatePlaybackButtons;
        RecordBtn.Click += (_, _) => RecordBtn_Click(this, new RoutedEventArgs());
        LoadFileBtn.Click += LoadFileBtn_Click;
        Loaded += (_, _) => ApplyStrings();
    }

    public void ApplyStrings()
    {
        var s = ThemeManager.Strings;
        MessageTextBox.SetValue(ToolTipService.ToolTipProperty, s.TextHint);
        EqualizerTitle.Text = s.AudioEqualizer;
        RecordBtn.LabelIdle = s.StartRecording;
        RecordBtn.LabelActive = s.StopRecording;
        RecordBtn.RefreshVisual();
        LoadFileLabel.Text = s.LoadAudioFile;
        PlayLabel.Text = s.Play;
        PauseLabel.Text = s.Pause;
        StopPlaybackLabel.Text = s.StopPlayback;
        SaveLabel.Text = s.SaveStego;
        VerifyLabel.Text = s.Verify;
    }

    private void OnSpectrumBands(double[] bands)
    {
        if (!Dispatcher.CheckAccess())
        {
            Dispatcher.BeginInvoke(() => OnSpectrumBands(bands));
            return;
        }
        _eqBands = bands;
        Equalizer.SetBands(bands);
        Equalizer.IsActive = _capture.IsRecording || _playback.HasSource;
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
        PlayButton.IsEnabled = !playing;
        PauseButton.IsEnabled = playing;
        StopPlaybackButton.IsEnabled = hasSource;
    }

    private async void RecordBtn_Click(object sender, RoutedEventArgs e)
    {
        if (_busy) return;
        var s = ThemeManager.Strings;

        if (_capture.IsRecording)
        {
            _busy = true;
            BusyBar.Visibility = Visibility.Visible;
            StatusText.Text = s.Processing;
            RecordBtn.IsEnabled = false;

            var messageText = MessageTextBox.Text.Trim();
            string? errorMessage = null;
            WavFile? coverWav = null;

            try
            {
                await Task.Run(() =>
                {
                    coverWav = _capture.StopAndRead();
                    if (coverWav is null)
                    {
                        errorMessage = s.ErrorNoRecording;
                        return;
                    }
                });

                if (errorMessage is not null)
                    StatusText.Text = errorMessage;
                else if (coverWav is not null)
                    await RunEmbedAsync(coverWav, messageText);
            }
            catch (Exception ex)
            {
                StatusText.Text = ex.Message;
            }
            finally
            {
                BusyBar.Visibility = Visibility.Collapsed;
                RecordBtn.IsEnabled = true;
                LoadFileBtn.IsEnabled = true;
                RecordBtn.IsRecording = false;
                Equalizer.IsActive = false;
                Equalizer.SetBands(new double[SpectrumAnalyzer.BandCount]);
                _busy = false;
            }

            return;
        }

        if (string.IsNullOrEmpty(MessageTextBox.Text.Trim()))
        {
            StatusText.Text = s.ErrorEmpty;
            return;
        }

        try
        {
            Equalizer.SetBands(new double[SpectrumAnalyzer.BandCount]);
            _capture.Start();
            _cover = null;
            _stego = null;
            _outcome = null;
            ResultPanel.Visibility = Visibility.Collapsed;
            VerifyBanner.Visibility = Visibility.Collapsed;
            StatusText.Text = s.Recording;
            RecordBtn.IsRecording = true;
            LoadFileBtn.IsEnabled = false;
            Equalizer.IsActive = true;
            MessageTextBox.IsEnabled = false;
        }
        catch (Exception ex)
        {
            StatusText.Text = ex.Message;
            RecordBtn.IsRecording = false;
        }
    }

    private async void LoadFileBtn_Click(object sender, RoutedEventArgs e)
    {
        if (_busy || _capture.IsRecording) return;
        var s = ThemeManager.Strings;
        var messageText = MessageTextBox.Text.Trim();
        if (string.IsNullOrEmpty(messageText))
        {
            StatusText.Text = s.ErrorEmpty;
            return;
        }

        var dlg = new OpenFileDialog { Filter = AudioInputLoader.OpenDialogFilter };
        if (dlg.ShowDialog() != true) return;

        _busy = true;
        BusyBar.Visibility = Visibility.Visible;
        StatusText.Text = s.Processing;
        LoadFileBtn.IsEnabled = false;
        RecordBtn.IsEnabled = false;

        WavFile? cover = null;
        string? error = null;
        await Task.Run(() =>
        {
            try
            {
                cover = AudioInputLoader.LoadFromPath(dlg.FileName);
            }
            catch (Exception ex)
            {
                error = ex.Message;
            }
        });

        if (error is not null)
        {
            StatusText.Text = error;
        }
        else if (cover is not null)
        {
            var preview = SpectrumAnalyzer.TimelineFromWav(cover);
            if (preview.Count > 0)
            {
                _eqBands = preview[0];
                Equalizer.SetBands(preview[0]);
            }
            await RunEmbedAsync(cover, messageText, Path.GetFileName(dlg.FileName));
        }

        BusyBar.Visibility = Visibility.Collapsed;
        LoadFileBtn.IsEnabled = true;
        RecordBtn.IsEnabled = true;
        _busy = false;
    }

    private async Task RunEmbedAsync(WavFile cover, string messageText, string? loadedFileName = null)
    {
        var s = ThemeManager.Strings;
        if (string.IsNullOrEmpty(messageText))
        {
            StatusText.Text = s.ErrorEmpty;
            return;
        }

        var required = MessageBits.BitLengthForText(messageText);
        if (required > cover.ToMono().Samples.Length)
        {
            StatusText.Text = $"{s.ErrorTooLong} ({required} bits)";
            return;
        }

        WatermarkOutcome? outcome = null;
        string? error = null;
        await Task.Run(() =>
        {
            try
            {
                outcome = AppState.Watermarking.Embed(messageText, cover);
            }
            catch (Exception ex)
            {
                error = ex.Message;
            }
        });

        if (error is not null)
            StatusText.Text = error;
        else if (outcome is not null)
        {
            ShowResult(outcome, cover);
            if (loadedFileName is not null)
                StatusText.Text = s.AudioFileLoaded(loadedFileName);
        }
    }

    private void ShowResult(WatermarkOutcome outcome, WavFile? cover)
    {
        var s = ThemeManager.Strings;
        _outcome = outcome;
        _cover = cover;
        _stego = outcome.Stego;
        StatusText.Text = string.Empty;
        MessageTextBox.IsEnabled = true;

        ResultPanel.Visibility = Visibility.Visible;
        ResultTitle.Text = s.SuccessSaved;
        CompareChartTitle.Text = s.CompareWaveformTitle;
        CompareChart.SetLegends(s.CoverWaveLegend, s.StegoWaveLegend);
        if (cover is not null)
        {
            CompareChart.CoverEnvelope = WaveformDisplay.EnvelopeFromWav(cover);
            CompareChart.StegoEnvelope = WaveformDisplay.EnvelopeFromWav(outcome.Stego);
        }
        MetricsTitle.Text = s.QualityMetrics;

        var m = outcome.Metrics;
        var duration = outcome.Stego.Samples.Length / (double)outcome.Stego.SampleRate;
        var chips = new List<MetricChipItem>
        {
            new("\uE121", s.Duration, $"{duration:F2} s"),
            new("\uE7C1", s.BitsEmbedded, $"{outcome.BitsEmbedded}"),
            new("\uE7F4", s.Capacity, $"{outcome.CapacityBits}"),
            new("\uE9F9", s.Utilization, $"{outcome.Utilization * 100:F1} %"),
            new("\uE8FD", s.MsgBitLength, $"{outcome.BitsEmbedded}"),
        };
        if (double.IsFinite(m.SnrDb))
            chips.Add(new("\uE9D9", s.SnrLabel, m.SnrDb.ToString("F2")));
        if (double.IsFinite(m.PsnrDb))
            chips.Add(new("\uE9D9", s.PsnrLabel, m.PsnrDb.ToString("F2")));
        chips.Add(new("\uE94C", s.BerLabel, m.BerPercent.ToString("F4")));
        chips.Add(new("\uE72E", s.NpcrLabel, m.NpcrPercent.ToString("F4")));
        chips.Add(new("\uE72E", s.UaciLabel, m.UaciPercent.ToString("F4")));
        MetricsItems.ItemsSource = chips;

        VerifyBanner.Visibility = Visibility.Collapsed;
        UpdatePlaybackButtons();
        ShowRecoveryBitsDialog(outcome.BitsEmbedded, outcome.CapacityBits);
    }

    private void ShowRecoveryBitsDialog(int msgBitLength, int capacityBits)
    {
        var owner = Window.GetWindow(this);
        var dlg = new RecoveryBitsDialog(msgBitLength, capacityBits);
        if (owner is not null)
            dlg.Owner = owner;
        dlg.ShowDialog();
    }

    private void PlayButton_Click(object sender, RoutedEventArgs e)
    {
        if (_stego is null) return;
        try
        {
            if (_playback.IsPaused)
                _playback.Resume();
            else
                _playback.Play(_stego);
        }
        catch (Exception ex) { StatusText.Text = ex.Message; }
    }

    private void PauseButton_Click(object sender, RoutedEventArgs e)
    {
        try { _playback.Pause(); }
        catch (Exception ex) { StatusText.Text = ex.Message; }
    }

    private void StopPlaybackButton_Click(object sender, RoutedEventArgs e)
    {
        try { _playback.Stop(); }
        catch (Exception ex) { StatusText.Text = ex.Message; }
    }

    private void SaveButton_Click(object sender, RoutedEventArgs e)
    {
        if (_stego is null) return;
        var dlg = new SaveFileDialog
        {
            Filter = "WAV (*.wav)|*.wav",
            FileName = StegoFileNaming.Build(_outcome!.BitsEmbedded),
        };
        if (dlg.ShowDialog() != true) return;
        File.WriteAllBytes(dlg.FileName, _stego.Encode());
        StatusText.Text = $"{ThemeManager.Strings.SuccessSaved}: {dlg.FileName}";
    }

    private async void VerifyButton_Click(object sender, RoutedEventArgs e)
    {
        if (_stego is null || _outcome is null) return;
        var s = ThemeManager.Strings;
        VerifyBanner.Visibility = Visibility.Visible;
        VerifyText.Text = s.Verifying;
        VerifyBanner.Background = (Brush)FindResource("SurfaceVariantBrush");
        VerifyBannerIcon.Text = "\uE121";
        VerifyText.Foreground = (Brush)FindResource("TextBrush");

        var original = MessageTextBox.Text.Trim();
        var bits = _outcome.BitsEmbedded;
        var stego = _stego;
        var extracted = await Task.Run(() => AppState.Watermarking.Extract(stego, bits));

        if (string.IsNullOrEmpty(extracted))
        {
            VerifyText.Text = s.VerifyEmpty;
            VerifyBanner.Background = new SolidColorBrush(Color.FromArgb(40, 179, 38, 30));
            VerifyBannerIcon.Text = "\uE783";
            VerifyText.Foreground = (Brush)FindResource("ErrorBrush");
        }
        else if (extracted == original)
        {
            VerifyText.Text = s.VerifyMatch;
            VerifyBanner.Background = new SolidColorBrush(Color.FromArgb(40, 46, 125, 50));
            VerifyBannerIcon.Text = "\uE73E";
            VerifyText.Foreground = (Brush)FindResource("SuccessBrush");
        }
        else
        {
            VerifyText.Text = s.VerifyMismatch;
            VerifyBanner.Background = new SolidColorBrush(Color.FromArgb(40, 179, 38, 30));
            VerifyBannerIcon.Text = "\uE783";
            VerifyText.Foreground = (Brush)FindResource("ErrorBrush");
        }
    }
}
