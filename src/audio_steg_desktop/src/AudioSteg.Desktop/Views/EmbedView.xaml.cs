using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using AudioSteg.Core.Audio;
using AudioSteg.Core.Stego;
using AudioSteg.Desktop.Models;
using AudioSteg.Desktop.Services;
using Microsoft.Win32;

namespace AudioSteg.Desktop.Views;

public partial class EmbedView : UserControl
{
    private readonly AudioCaptureService _capture = new();
    private readonly AudioPlaybackService _playback = new();
    private readonly List<double> _amps = [];
    private WavFile? _stego;
    private WatermarkOutcome? _outcome;
    private bool _busy;

    public EmbedView()
    {
        InitializeComponent();
        _capture.AmplitudeDb += OnAmplitudeDb;
        RecordBtn.Click += (_, _) => RecordBtn_Click(this, new RoutedEventArgs());
        Loaded += (_, _) => ApplyStrings();
    }

    public void ApplyStrings()
    {
        var s = ThemeManager.Strings;
        MessageTextBox.SetValue(ToolTipService.ToolTipProperty, s.TextHint);
        RecordBtn.LabelIdle = s.StartRecording;
        RecordBtn.LabelActive = s.StopRecording;
        RecordBtn.RefreshVisual();
        PlayLabel.Text = s.Play;
        SaveLabel.Text = s.SaveStego;
        VerifyLabel.Text = s.Verify;
    }

    private void OnAmplitudeDb(double db)
    {
        if (!Dispatcher.CheckAccess())
        {
            Dispatcher.BeginInvoke(() => OnAmplitudeDb(db));
            return;
        }
        _amps.Add(db);
        if (_amps.Count > 200) _amps.RemoveAt(0);
        Waveform.IsActive = _capture.IsRecording;
        Waveform.SetSamples(_amps);
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
            WatermarkOutcome? outcome = null;

            try
            {
                await Task.Run(() =>
                {
                    var cover = _capture.StopAndRead();
                    if (cover is null)
                    {
                        errorMessage = s.ErrorNoRecording;
                        return;
                    }

                    if (string.IsNullOrEmpty(messageText))
                    {
                        errorMessage = s.ErrorEmpty;
                        return;
                    }

                    var required = MessageBits.BitLengthForText(messageText);
                    if (required > cover.ToMono().Samples.Length)
                    {
                        errorMessage = $"{s.ErrorTooLong} ({required} bits)";
                        return;
                    }

                    outcome = AppState.Watermarking.Embed(messageText, cover);
                });

                if (errorMessage is not null)
                    StatusText.Text = errorMessage;
                else if (outcome is not null)
                    ShowResult(outcome);
            }
            catch (Exception ex)
            {
                StatusText.Text = ex.Message;
            }
            finally
            {
                BusyBar.Visibility = Visibility.Collapsed;
                RecordBtn.IsEnabled = true;
                RecordBtn.IsRecording = false;
                Waveform.IsActive = false;
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
            _amps.Clear();
            Waveform.SetSamples(_amps);
            _capture.Start();
            _stego = null;
            _outcome = null;
            ResultPanel.Visibility = Visibility.Collapsed;
            VerifyBanner.Visibility = Visibility.Collapsed;
            StatusText.Text = s.Recording;
            RecordBtn.IsRecording = true;
            Waveform.IsActive = true;
            MessageTextBox.IsEnabled = false;
        }
        catch (Exception ex)
        {
            StatusText.Text = ex.Message;
            RecordBtn.IsRecording = false;
        }
    }

    private void ShowResult(WatermarkOutcome outcome)
    {
        var s = ThemeManager.Strings;
        _outcome = outcome;
        _stego = outcome.Stego;
        StatusText.Text = string.Empty;
        MessageTextBox.IsEnabled = true;

        ResultPanel.Visibility = Visibility.Visible;
        ResultTitle.Text = s.SuccessSaved;
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
    }

    private void PlayButton_Click(object sender, RoutedEventArgs e)
    {
        if (_stego is null) return;
        try { _playback.Play(_stego); }
        catch (Exception ex) { StatusText.Text = ex.Message; }
    }

    private void SaveButton_Click(object sender, RoutedEventArgs e)
    {
        if (_stego is null) return;
        var dlg = new SaveFileDialog
        {
            Filter = Core.Audio.AudioInputLoader.OpenDialogFilter,
            FileName = $"stego_{DateTime.Now:yyyyMMdd_HHmmss}.wav",
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
