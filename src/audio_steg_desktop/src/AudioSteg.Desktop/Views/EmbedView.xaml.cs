using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;
using AudioSteg.Core.Audio;
using AudioSteg.Core.Stego;
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
        _capture.AmplitudeDb += db =>
        {
            Dispatcher.Invoke(() =>
            {
                _amps.Add(db);
                if (_amps.Count > 200) _amps.RemoveAt(0);
                DrawWaveform();
            });
        };
        Loaded += (_, _) => ApplyStrings();
    }

    public void ApplyStrings()
    {
        var s = ThemeManager.Strings;
        MessageTextBox.SetValue(ToolTipService.ToolTipProperty, s.TextHint);
        RefreshRecordButton();
    }

    private void DrawWaveform()
    {
        WaveformBar.Child = null;
        if (_amps.Count == 0) return;
        var canvas = new Canvas { Width = WaveformBar.ActualWidth > 0 ? WaveformBar.ActualWidth : 400, Height = 48 };
        var min = _amps.Min();
        var max = _amps.Max();
        var range = Math.Max(max - min, 1e-6);
        for (var i = 0; i < _amps.Count; i++)
        {
            var x = i * canvas.Width / Math.Max(_amps.Count - 1, 1);
            var h = ((_amps[i] - min) / range) * 40 + 4;
            var rect = new Rectangle
            {
                Width = Math.Max(canvas.Width / _amps.Count - 1, 2),
                Height = h,
                Fill = (Brush)FindResource("AccentBrush"),
                RadiusX = 1,
                RadiusY = 1,
            };
            Canvas.SetLeft(rect, x);
            Canvas.SetBottom(rect, 4);
            canvas.Children.Add(rect);
        }
        WaveformBar.Child = canvas;
    }

    private void RefreshRecordButton()
    {
        var s = ThemeManager.Strings;
        RecordButton.Content = _capture.IsRecording ? s.StopRecording : s.StartRecording;
        RecordButton.Background = _capture.IsRecording
            ? (Brush)FindResource("ErrorBrush")
            : (Brush)FindResource("AccentBrush");
        RecordButton.Foreground = Brushes.White;
    }

    private async void RecordButton_Click(object sender, RoutedEventArgs e)
    {
        if (_busy) return;
        var s = ThemeManager.Strings;

        if (_capture.IsRecording)
        {
            _busy = true;
            BusyBar.Visibility = Visibility.Visible;
            StatusText.Text = s.Processing;
            RecordButton.IsEnabled = false;

            await Task.Run(() =>
            {
                try
                {
                    var cover = _capture.StopAndRead();
                    if (cover is null)
                    {
                        Dispatcher.Invoke(() => StatusText.Text = "No recorded audio.");
                        return;
                    }

                    var text = MessageTextBox.Text.Trim();
                    if (string.IsNullOrEmpty(text))
                    {
                        Dispatcher.Invoke(() => StatusText.Text = s.ErrorEmpty);
                        return;
                    }

                    var required = MessageBits.BitLengthForText(text);
                    if (required > cover.ToMono().Samples.Length)
                    {
                        Dispatcher.Invoke(() =>
                            StatusText.Text = $"{s.ErrorTooLong} ({required} bits)");
                        return;
                    }

                    var outcome = AppState.Watermarking.Embed(text, cover);
                    Dispatcher.Invoke(() => ShowResult(outcome, null));
                }
                catch (Exception ex)
                {
                    Dispatcher.Invoke(() => StatusText.Text = ex.Message);
                }
            });

            BusyBar.Visibility = Visibility.Collapsed;
            RecordButton.IsEnabled = true;
            _busy = false;
            RefreshRecordButton();
            return;
        }

        var msg = MessageTextBox.Text.Trim();
        if (string.IsNullOrEmpty(msg))
        {
            StatusText.Text = s.ErrorEmpty;
            return;
        }

        try
        {
            _amps.Clear();
            _capture.Start();
            _stego = null;
            _outcome = null;
            ResultPanel.Visibility = Visibility.Collapsed;
            StatusText.Text = s.Recording;
            RefreshRecordButton();
        }
        catch (Exception ex)
        {
            StatusText.Text = ex.Message;
        }
    }

    private void ShowResult(WatermarkOutcome outcome, string? error)
    {
        var s = ThemeManager.Strings;
        _outcome = outcome;
        _stego = outcome.Stego;
        StatusText.Text = error ?? string.Empty;

        ResultPanel.Visibility = Visibility.Visible;
        ResultTitle.Text = s.QualityMetrics;

        var m = outcome.Metrics;
        var duration = outcome.Stego.Samples.Length / (double)outcome.Stego.SampleRate;
        MetricsText.Text =
            $"{s.Duration}: {duration:F2} s\n" +
            $"{s.BitsEmbedded}: {outcome.BitsEmbedded}\n" +
            $"{s.Capacity}: {outcome.CapacityBits}\n" +
            $"{s.Utilization}: {outcome.Utilization * 100:F1} %\n" +
            $"{s.MsgBitLength}: {outcome.BitsEmbedded}\n" +
            $"{s.SnrLabel}: {FormatMetric(m.SnrDb)}\n" +
            $"{s.PsnrLabel}: {FormatMetric(m.PsnrDb)}\n" +
            $"{s.BerLabel}: {m.BerPercent:F4}\n" +
            $"{s.NpcrLabel}: {m.NpcrPercent:F4}\n" +
            $"{s.UaciLabel}: {m.UaciPercent:F4}";

        PlayButton.Content = s.Play;
        SaveButton.Content = s.SaveStego;
        VerifyButton.Content = s.Verify;
        VerifyText.Visibility = Visibility.Collapsed;
    }

    private static string FormatMetric(double v) =>
        double.IsFinite(v) ? v.ToString("F2") : "∞";

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
            Filter = "WAV files (*.wav)|*.wav",
            FileName = $"stego_{DateTime.Now:yyyyMMdd_HHmmss}.wav",
        };
        if (dlg.ShowDialog() != true) return;
        File.WriteAllBytes(dlg.FileName, _stego.Encode());
        StatusText.Text = $"{ThemeManager.Strings.Copied}: {dlg.FileName}";
    }

    private async void VerifyButton_Click(object sender, RoutedEventArgs e)
    {
        if (_stego is null || _outcome is null) return;
        var s = ThemeManager.Strings;
        VerifyText.Visibility = Visibility.Visible;
        VerifyText.Text = s.Verifying;
        VerifyText.Foreground = (Brush)FindResource("MutedBrush");

        var original = MessageTextBox.Text.Trim();
        var extracted = await Task.Run(() =>
            AppState.Watermarking.Extract(_stego, _outcome.BitsEmbedded));

        if (string.IsNullOrEmpty(extracted))
            VerifyText.Text = s.VerifyEmpty;
        else if (extracted == original)
        {
            VerifyText.Text = s.VerifyMatch;
            VerifyText.Foreground = (Brush)FindResource("SuccessBrush");
        }
        else
        {
            VerifyText.Text = s.VerifyMismatch;
            VerifyText.Foreground = (Brush)FindResource("ErrorBrush");
        }
    }
}
