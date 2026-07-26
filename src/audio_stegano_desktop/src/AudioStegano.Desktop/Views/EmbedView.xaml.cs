using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;
using AudioStegano.Core.Audio;
using AudioStegano.Core.Stego;
using AudioStegano.Desktop.Dialogs;
using AudioStegano.Desktop.Localization;
using AudioStegano.Desktop.Models;
using AudioStegano.Desktop.Services;
using HelpSection = AudioStegano.Desktop.Dialogs.HelpSection;
using Microsoft.Win32;

namespace AudioStegano.Desktop.Views;

public partial class EmbedView : UserControl
{
    private readonly AudioCaptureService _capture = new();
    private readonly AudioPlaybackService _playback = new();
    private double[] _eqBands = new double[SpectrumAnalyzer.BandCount];
    private WavFile? _cover;
    private WavFile? _stego;
    private WatermarkOutcome? _outcome;
    private WavFile? _payloadAudio;
    private bool _audioPayloadMode;
    private bool _recordingPayload;
    private bool _busy;
    private bool _verifying;
    private bool _updatingMessageText;
    private DispatcherTimer? _recordTimer;
    private DateTime _recordStartUtc;

    public EmbedView()
    {
        InitializeComponent();
        _capture.SpectrumBands += OnSpectrumBands;
        _playback.SpectrumBands += OnSpectrumBands;
        _playback.PlaybackStateChanged += UpdatePlaybackButtons;
        RecordBtn.Click += (_, _) => RecordBtn_Click(this, new RoutedEventArgs());
        LoadFileBtn.Click += (_, _) => LoadFileBtn_Click(this, new RoutedEventArgs());
        Loaded += (_, _) =>
        {
            ApplyStrings();
            ApplyEmbedLayout();
            AudioFileDropHelper.Enable(AudioSourceCard, OnAudioFileDroppedAsync);
        };
        MetricsItems.PreviewMouseLeftButtonDown += MetricsItems_PreviewMouseLeftButtonDown;
    }

    public void ApplyStrings()
    {
        var s = ThemeManager.Strings;
        PayloadModeText.Content = s.EmbedPayloadTextTab;
        PayloadModeAudio.Content = s.EmbedPayloadAudioTab;
        MessageLabel.Text = s.TextHint;
        MessageTextBox.SetValue(ToolTipService.ToolTipProperty, s.TextHint);
        AudioPayloadHint.Text = s.EmbedPayloadAudioHint;
        ClearPayloadAudioLabel.Text = s.ClearPayloadAudio;
        AudioSourceOrLabel.Text = s.AudioSourceOr;
        EqualizerTitle.Text = s.AudioEqualizer;
        RefreshRecordButtonLabels();
        LoadFileBtn.Label = s.LoadAudioFile;
        LoadFileBtn.RefreshVisual();
        ToolTipService.SetToolTip(PlayButton, s.Play);
        ToolTipService.SetToolTip(PauseButton, s.Pause);
        ToolTipService.SetToolTip(StopPlaybackButton, s.StopPlayback);
        ToolTipService.SetToolTip(CopyMessageButton, s.Copy);
        SaveLabel.Text = s.SaveStego;
        ShareLabel.Text = s.ShareStego;
        VerifyLabel.Text = s.Verify;
        MetricsTapHint.Text = s.MetricHelpTapHint;
        ToolTipService.SetToolTip(NewEmbedFab, s.EmbedNew);
        ToolTipService.SetToolTip(HelpFab, s.HelpTooltip);
        UpdateFabStates();
        UpdateMessageBitCounter();
        UpdateAudioPayloadUi();
    }

    private void RefreshRecordButtonLabels()
    {
        var s = ThemeManager.Strings;
        if (_audioPayloadMode && _payloadAudio is null)
        {
            RecordBtn.LabelIdle = s.RecordPayloadAudio;
            RecordBtn.LabelActive = s.StopPayloadAudio;
        }
        else
        {
            RecordBtn.LabelIdle = s.StartRecording;
            RecordBtn.LabelActive = s.StopRecording;
        }
        RecordBtn.RefreshVisual();
    }

    private void PayloadMode_Checked(object sender, RoutedEventArgs e)
    {
        if (!IsLoaded) return;
        _audioPayloadMode = PayloadModeAudio.IsChecked == true;
        TextPayloadPanel.Visibility = _audioPayloadMode ? Visibility.Collapsed : Visibility.Visible;
        AudioPayloadPanel.Visibility = _audioPayloadMode ? Visibility.Visible : Visibility.Collapsed;
        if (!_audioPayloadMode)
            _payloadAudio = null;
        RefreshRecordButtonLabels();
        UpdateAudioPayloadUi();
    }

    private void ClearPayloadAudio_Click(object sender, RoutedEventArgs e)
    {
        _payloadAudio = null;
        StatusText.Text = string.Empty;
        UpdateAudioPayloadUi();
        RefreshRecordButtonLabels();
    }

    private void UpdateAudioPayloadUi()
    {
        var s = ThemeManager.Strings;
        var budget = AppConfig.Current.DefaultFixedMessageBitLength;
        if (_payloadAudio is null)
        {
            AudioPayloadBudget.Text = s.PayloadAudioBudgetLabel(0, budget);
            ClearPayloadAudioBtn.Visibility = Visibility.Collapsed;
        }
        else
        {
            var used = PayloadEnvelope.BitLengthForAudio(_payloadAudio);
            AudioPayloadBudget.Text = s.PayloadAudioBudgetLabel(used, budget);
            ClearPayloadAudioBtn.Visibility = Visibility.Visible;
        }
    }

    private void UpdateFabStates()
    {
        var canNew = (!_busy || _capture.IsRecording) && !_verifying;
        NewEmbedFab.IsEnabled = canNew;
        UpdateResultActionButtons();
    }

    private void UpdateResultActionButtons()
    {
        var enabled = _stego is not null && !_verifying;
        SaveButton.IsEnabled = enabled;
        ShareButton.IsEnabled = enabled;
        VerifyButton.IsEnabled = enabled;
        CopyMessageButton.IsEnabled = enabled && !string.IsNullOrWhiteSpace(MessageTextBox.Text);
        if (!enabled || _verifying)
        {
            PlayButton.IsEnabled = false;
            PauseButton.IsEnabled = false;
            StopPlaybackButton.IsEnabled = false;
        }
        else
            UpdatePlaybackButtons();
    }

    private void CopyMessageButton_Click(object sender, RoutedEventArgs e)
    {
        var text = MessageTextBox.Text;
        if (string.IsNullOrWhiteSpace(text)) return;
        Clipboard.SetText(text);
        StatusText.Text = ThemeManager.Strings.Copied;
    }

    private void HelpFab_Click(object sender, RoutedEventArgs e)
    {
        var owner = Window.GetWindow(this);
        var dlg = new HelpDialog(HelpSection.Embed);
        if (owner is not null)
            dlg.Owner = owner;
        dlg.ShowDialog();
    }

    private void NewEmbedFab_Click(object sender, RoutedEventArgs e)
    {
        if (_verifying) return;
        if (_busy && !_capture.IsRecording) return;

        if (_capture.IsRecording)
        {
            _capture.Cancel();
            StopRecordTimer();
            RecordBtn.IsRecording = false;
            Equalizer.IsActive = false;
            Equalizer.SetBands(new double[SpectrumAnalyzer.BandCount]);
            StatusText.Text = string.Empty;
            MessageTextBox.IsEnabled = true;
            _busy = false;
            UpdateFabStates();
            return;
        }

        try { _playback.Stop(); }
        catch { /* ignore */ }
        MessageTextBox.Clear();
        ResetForNewEmbed();
        SessionLog.Write("Embed: new session");
        UpdateFabStates();
    }

    private Task OnAudioFileDroppedAsync(string path)
    {
        if (_busy || _capture.IsRecording) return Task.CompletedTask;
        if (ResultPanel.Visibility == Visibility.Visible)
            ResetForNewEmbed();
        return LoadAndEmbedFromPathAsync(path);
    }

    private void ShareButton_Click(object sender, RoutedEventArgs e)
    {
        if (_stego is null || _outcome is null) return;
        var s = ThemeManager.Strings;
        var owner = Window.GetWindow(this);
        if (StegoShareService.TryShare(_stego, _outcome.BitsEmbedded, owner, s, out var status) && status is not null)
            StatusText.Text = status;
    }

    private void MetricsItems_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (FindMetricChip(e.OriginalSource) is not { } chip)
            return;

        var owner = Window.GetWindow(this);
        var dlg = new MetricHelpDialog(chip.Kind);
        if (owner is not null)
            dlg.Owner = owner;
        dlg.ShowDialog();
        e.Handled = true;
    }

    private static MetricChipItem? FindMetricChip(object? source)
    {
        if (source is not DependencyObject d)
            return null;
        for (var cur = d; cur != null; cur = VisualTreeHelper.GetParent(cur))
        {
            if (cur is FrameworkElement { DataContext: MetricChipItem chip })
                return chip;
        }
        return null;
    }

    private static bool IsEmbedCapacityError(string message) =>
        message.Contains("too long", StringComparison.OrdinalIgnoreCase) ||
        message.Contains("Message too long", StringComparison.Ordinal);

    private static bool IsEmbedIntegrityError(string message)
    {
        var m = message.ToLowerInvariant();
        return m.Contains("integrity") ||
               m.Contains("ber is") ||
               m.Contains("bit mismatch") ||
               m.Contains("wav round-trip") ||
               m.Contains("recovered");
    }

    private void ShowEmbedWarning(string message)
    {
        var s = ThemeManager.Strings;
        var owner = Window.GetWindow(this);
        if (owner is not null)
            MessageBox.Show(owner, message, s.EmbedWarningTitle, MessageBoxButton.OK, MessageBoxImage.Warning);
        else
            MessageBox.Show(message, s.EmbedWarningTitle, MessageBoxButton.OK, MessageBoxImage.Warning);
        ReleaseEmbedInteractionLocks();
    }

    private void ReleaseEmbedInteractionLocks()
    {
        BusyBar.Visibility = Visibility.Collapsed;
        RecordBtn.IsEnabled = true;
        LoadFileBtn.IsEnabled = true;
        RecordBtn.IsRecording = false;
        Equalizer.IsActive = false;
        MessageTextBox.IsEnabled = true;
        _busy = false;
        StatusText.Text = string.Empty;
        UpdateFabStates();
    }

    private void MessageTextBox_TextChanged(object sender, TextChangedEventArgs e)
    {
        if (_updatingMessageText) return;
        ContentTextDirectionHelper.ApplyTo(MessageTextBox, MessageTextBox.Text);
        EnforceMessageBitLimitIfNeeded();
        UpdateMessageBitCounter();
    }

    private void EnforceMessageBitLimitIfNeeded()
    {
        if (!AppState.Settings.DefaultFixedMessageBitLimit) return;

        var max = AppConfig.Current.DefaultFixedMessageBitLength;
        var text = MessageTextBox.Text;
        if (PayloadEnvelope.BitLengthForText(text) <= max) return;

        _updatingMessageText = true;
        while (text.Length > 0 && PayloadEnvelope.BitLengthForText(text) > max)
            text = text[..^1];
        var caret = Math.Min(MessageTextBox.CaretIndex, text.Length);
        MessageTextBox.Text = text;
        MessageTextBox.CaretIndex = caret;
        _updatingMessageText = false;
    }

    public void UpdateMessageBitCounter()
    {
        if (!IsLoaded) return;
        EnforceMessageBitLimitIfNeeded();
        var s = ThemeManager.Strings;
        var used = PayloadEnvelope.BitLengthForText(MessageTextBox.Text);
        if (AppState.Settings.DefaultFixedMessageBitLimit)
        {
            var remaining = AppConfig.Current.DefaultFixedMessageBitLength - used;
            MessageBitsCounter.Text = s.MessageBitsUsedAndRemaining(used, remaining);
        }
        else
            MessageBitsCounter.Text = s.MessageBitsUsed(used);
    }

    private void ApplyEmbedLayout()
    {
        var showLoad = AppConfig.ShowEmbedLoadFileForUi;
        LoadFileBtn.Visibility = showLoad ? Visibility.Visible : Visibility.Collapsed;
        AudioSourceOrLabel.Visibility = showLoad ? Visibility.Visible : Visibility.Collapsed;
        if (showLoad)
        {
            Grid.SetColumn(RecordBtn, 0);
            Grid.SetColumnSpan(RecordBtn, 1);
        }
        else
        {
            Grid.SetColumn(RecordBtn, 0);
            Grid.SetColumnSpan(RecordBtn, 3);
        }
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
        var paused = _playback.IsPaused;
        PlayButton.IsEnabled = !playing && (_stego is not null);
        PauseButton.IsEnabled = playing;
        StopPlaybackButton.IsEnabled = hasSource && (playing || paused);
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
            WavFile? recorded = null;
            var wasPayload = _recordingPayload;

            try
            {
                await Task.Run(() =>
                {
                    recorded = _capture.StopAndRead();
                    if (recorded is null)
                        errorMessage = s.ErrorNoRecording;
                });

                if (errorMessage is not null)
                    StatusText.Text = errorMessage;
                else if (recorded is not null && wasPayload)
                {
                    var wallClock = DateTime.UtcNow - _recordStartUtc;
                    recorded = SampleRateReconcile.Reconcile(recorded, wallClock);
                    var budget = AppConfig.Current.DefaultFixedMessageBitLength;
                    var needed = PayloadEnvelope.BitLengthForAudio(recorded);
                    if (needed > budget)
                    {
                        ShowEmbedWarning(s.ErrorPayloadAudioBudget);
                        _payloadAudio = null;
                    }
                    else
                    {
                        _payloadAudio = recorded;
                        StatusText.Text = s.PayloadAudioReady;
                        UpdateAudioPayloadUi();
                        RefreshRecordButtonLabels();
                    }
                }
                else if (recorded is not null)
                    await RunEmbedAsync(recorded, messageText);
            }
            catch (Exception ex)
            {
                SessionLog.Write("Embed: record stop failed", ex);
                StatusText.Text = ex.Message;
            }
            finally
            {
                _recordingPayload = false;
                Equalizer.SetBands(new double[SpectrumAnalyzer.BandCount]);
                StopRecordTimer();
                ReleaseEmbedInteractionLocks();
            }

            return;
        }

        if (_audioPayloadMode && _payloadAudio is null)
        {
            _busy = true;
            try
            {
                SessionLog.Write("Embed: payload record start");
                _recordingPayload = true;
                _capture.Start(PayloadAudioDefaults.SampleRate);
                StartRecordTimer();
                StatusText.Text = s.Recording;
                RefreshRecordButtonLabels();
            }
            catch (Exception ex)
            {
                _recordingPayload = false;
                SessionLog.Write("Embed: payload record start failed", ex);
                StatusText.Text = ex.Message;
            }
            finally
            {
                ReleaseEmbedInteractionLocks();
            }
            return;
        }

        if (_audioPayloadMode)
        {
            if (_payloadAudio is null)
            {
                ShowEmbedWarning(s.ErrorEmptyPayloadAudio);
                return;
            }
        }
        else if (string.IsNullOrEmpty(MessageTextBox.Text.Trim()))
        {
            ShowEmbedWarning(s.ErrorEmpty);
            return;
        }

        _busy = true;
        try
        {
            SessionLog.Write("Embed: cover record start");
            _recordingPayload = false;
            _capture.Start(44100);
            StartRecordTimer();
            StatusText.Text = s.Recording;
            RefreshRecordButtonLabels();
        }
        catch (Exception ex)
        {
            SessionLog.Write("Embed: record start failed", ex);
            StatusText.Text = ex.Message;
        }
        finally
        {
            ReleaseEmbedInteractionLocks();
        }
    }

    private void StartRecordTimer()
    {
        _recordStartUtc = DateTime.UtcNow;
        Equalizer.RecordingElapsed = TimeSpan.Zero;
        _recordTimer?.Stop();
        _recordTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(1) };
        _recordTimer.Tick += (_, _) =>
            Equalizer.RecordingElapsed = DateTime.UtcNow - _recordStartUtc;
        _recordTimer.Start();
    }

    private void StopRecordTimer()
    {
        _recordTimer?.Stop();
        _recordTimer = null;
        Equalizer.RecordingElapsed = null;
    }

    private async void LoadFileBtn_Click(object sender, RoutedEventArgs e)
    {
        if (_busy || _capture.IsRecording) return;
        var dlg = new OpenFileDialog { Filter = AudioInputLoader.OpenDialogFilter };
        if (dlg.ShowDialog() != true) return;
        await LoadAndEmbedFromPathAsync(dlg.FileName);
    }

    private async Task LoadAndEmbedFromPathAsync(string filePath)
    {
        if (_busy || _capture.IsRecording) return;
        if (ResultPanel.Visibility == Visibility.Visible)
            ResetForNewEmbed();

        var s = ThemeManager.Strings;
        var messageText = MessageTextBox.Text.Trim();
        if (_audioPayloadMode)
        {
            if (_payloadAudio is null)
            {
                ShowEmbedWarning(s.ErrorEmptyPayloadAudio);
                return;
            }
        }
        else if (string.IsNullOrEmpty(messageText))
        {
            ShowEmbedWarning(s.ErrorEmpty);
            return;
        }

        _busy = true;
        BusyBar.Visibility = Visibility.Visible;
        StatusText.Text = s.Processing;
        LoadFileBtn.IsEnabled = false;
        RecordBtn.IsEnabled = false;
        UpdateFabStates();

        WavFile? cover = null;
        string? error = null;
        await Task.Run(() =>
        {
            try
            {
                cover = AudioInputLoader.LoadFromPath(filePath);
            }
            catch (Exception ex)
            {
                error = AudioLoadErrors.Format(ThemeManager.Strings, ex);
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
            await RunEmbedAsync(cover, messageText, Path.GetFileName(filePath));
        }

        ReleaseEmbedInteractionLocks();
    }

    private async Task RunEmbedAsync(WavFile cover, string messageText, string? loadedFileName = null)
    {
        var s = ThemeManager.Strings;
        var useFixedLen = AppState.Settings.DefaultFixedMessageBitLimit;
        var fixedLen = useFixedLen ? AppConfig.Current.DefaultFixedMessageBitLength : (int?)null;

        WatermarkOutcome? outcome = null;
        string? error = null;

        if (_audioPayloadMode)
        {
            if (_payloadAudio is null)
            {
                ShowEmbedWarning(s.ErrorEmptyPayloadAudio);
                return;
            }
            try
            {
                var bits = PayloadEnvelope.PackAudioBits(_payloadAudio, fixedBitLength: fixedLen);
                if (bits.Length > cover.ToMono().Samples.Length)
                {
                    ShowEmbedWarning(s.ErrorTooLong);
                    return;
                }
                await Task.Run(() =>
                {
                    try
                    {
                        outcome = AppState.Watermarking.EmbedBitsWithMetrics(cover, bits);
                    }
                    catch (Exception ex)
                    {
                        error = ex.Message;
                    }
                });
            }
            catch (ArgumentException)
            {
                ShowEmbedWarning(s.ErrorPayloadAudioBudget);
                return;
            }
        }
        else
        {
            if (string.IsNullOrEmpty(messageText))
            {
                ShowEmbedWarning(s.ErrorEmpty);
                return;
            }

            var required = useFixedLen
                ? AppConfig.Current.DefaultFixedMessageBitLength
                : PayloadEnvelope.BitLengthForText(messageText);
            if (required > cover.ToMono().Samples.Length)
            {
                ShowEmbedWarning(s.ErrorTooLong);
                return;
            }

            if (useFixedLen &&
                PayloadEnvelope.BitLengthForText(messageText) >
                AppConfig.Current.DefaultFixedMessageBitLength)
            {
                ShowEmbedWarning(s.ErrorTooLong);
                return;
            }

            await Task.Run(() =>
            {
                try
                {
                    outcome = AppState.Watermarking.Embed(messageText, cover, fixedLen);
                }
                catch (Exception ex)
                {
                    error = ex.Message;
                }
            });
        }

        if (error is not null)
        {
            if (IsEmbedCapacityError(error))
                ShowEmbedWarning(s.ErrorTooLong);
            else if (IsEmbedIntegrityError(error))
                ShowEmbedWarning(s.ErrorEmbedIntegrity);
            else
                StatusText.Text = error;
        }
        else if (outcome is not null)
        {
            ShowResult(outcome, cover);
            if (loadedFileName is not null)
                StatusText.Text = s.AudioFileLoaded(loadedFileName);
        }
    }

    private void ResetForNewEmbed()
    {
        try { _playback.Stop(); }
        catch { /* ignore */ }
        _cover = null;
        _stego = null;
        _outcome = null;
        _payloadAudio = null;
        _recordingPayload = false;
        _audioPayloadMode = false;
        PayloadModeText.IsChecked = true;
        PayloadModeAudio.IsChecked = false;
        TextPayloadPanel.Visibility = Visibility.Visible;
        AudioPayloadPanel.Visibility = Visibility.Collapsed;
        ResultPanel.Visibility = Visibility.Collapsed;
        VerifyBanner.Visibility = Visibility.Collapsed;
        EmbedInputPanel.Visibility = Visibility.Visible;
        MessageTextBox.IsEnabled = true;
        StatusText.Text = string.Empty;
        Equalizer.SetBands(new double[SpectrumAnalyzer.BandCount]);
        UpdateAudioPayloadUi();
        RefreshRecordButtonLabels();
        UpdatePlaybackButtons();
        UpdateFabStates();
    }

    private void ShowResult(WatermarkOutcome outcome, WavFile? cover)
    {
        var s = ThemeManager.Strings;
        _outcome = outcome;
        _cover = cover;
        _stego = outcome.Stego;
        StatusText.Text = string.Empty;
        EmbedInputPanel.Visibility = Visibility.Collapsed;

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
        var msgLen = outcome.OriginalBits.Length;
        var chips = new List<MetricChipItem>
        {
            new("\uE121", s.Duration, $"{duration:F2} s", EmbedMetricKind.Duration),
            new("\uE7C1", s.BitsEmbedded, $"{outcome.BitsEmbedded}", EmbedMetricKind.BitsEmbedded),
            new("\uE7F4", s.Capacity, $"{outcome.CapacityBits}", EmbedMetricKind.Capacity),
            new("\uE9F9", s.Utilization, $"{outcome.Utilization * 100:F1} %", EmbedMetricKind.Utilization),
        };
        if (!AppState.Settings.DefaultFixedMessageBitLimit)
            chips.Add(new("\uE8FD", s.MsgBitLength, $"{msgLen}", EmbedMetricKind.MsgBitLength));
        if (double.IsFinite(m.SnrDb))
            chips.Add(new("\uE9D9", s.SnrLabel, m.SnrDb.ToString("F2"), EmbedMetricKind.Snr));
        if (double.IsFinite(m.PsnrDb))
            chips.Add(new("\uE9D9", s.PsnrLabel, m.PsnrDb.ToString("F2"), EmbedMetricKind.Psnr));
        chips.Add(new("\uE94C", s.BerLabel, m.BerPercent.ToString("F4"), EmbedMetricKind.Ber));
        chips.Add(new("\uE72E", s.NpcrLabel, m.NpcrPercent.ToString("F4"), EmbedMetricKind.Npcr));
        chips.Add(new("\uE72E", s.UaciLabel, m.UaciPercent.ToString("F4"), EmbedMetricKind.Uaci));
        MetricsItems.ItemsSource = chips;

        VerifyBanner.Visibility = Visibility.Visible;
        VerifyProgress.Visibility = Visibility.Collapsed;
        VerifyIcon.Visibility = Visibility.Visible;
        VerifyText.Text = s.VerifyMatch;
        VerifyBanner.Background = new SolidColorBrush(Color.FromArgb(40, 46, 125, 50));
        VerifyBannerIcon.Text = "\uE73E";
        VerifyText.Foreground = (Brush)FindResource("SuccessBrush");
        UpdatePlaybackButtons();
        UpdateResultActionButtons();
        var showRecovery = !AppState.Settings.DefaultFixedMessageBitLimit &&
                           AppConfig.Current.ShowEmbedRecoveryDialog;
        ShowEmbedCompleteDialog(outcome.BitsEmbedded, outcome.CapacityBits, showRecovery);
        ScrollResultIntoView();
        SessionLog.Write($"Embed: success bits={outcome.BitsEmbedded}");
    }

    private void ScrollResultIntoView()
    {
        Dispatcher.BeginInvoke(() =>
        {
            ResultPanel.BringIntoView();
        }, System.Windows.Threading.DispatcherPriority.Loaded);
    }

    private void ShowEmbedCompleteDialog(int msgBitLength, int capacityBits, bool showRecoveryReminder)
    {
        var owner = Window.GetWindow(this);
        if (showRecoveryReminder)
        {
            var dlg = new RecoveryBitsDialog(msgBitLength, capacityBits);
            if (owner is not null)
                dlg.Owner = owner;
            dlg.ShowDialog();
            return;
        }

        var s = ThemeManager.Strings;
        MessageBox.Show(
            owner,
            s.SuccessSaved,
            s.EmbedCompleteTitle,
            MessageBoxButton.OK,
            MessageBoxImage.Information);
    }

    private void PlayButton_Click(object sender, RoutedEventArgs e)
    {
        if (_stego is null) return;
        try
        {
            if (_playback.HasSource && (_playback.IsPaused || !_playback.IsPlaying))
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
        if (_stego is null || _outcome is null || _verifying) return;
        var s = ThemeManager.Strings;
        _verifying = true;
        UpdateFabStates();
        UpdateResultActionButtons();
        VerifyProgress.Visibility = Visibility.Visible;
        VerifyIcon.Visibility = Visibility.Collapsed;
        VerifyBanner.Visibility = Visibility.Visible;
        VerifyText.Text = s.Verifying;
        VerifyBanner.Background = (Brush)FindResource("SurfaceVariantBrush");
        VerifyBannerIcon.Text = "\uE121";
        VerifyText.Foreground = (Brush)FindResource("TextBrush");

        var original = MessageTextBox.Text.Trim();
        var bits = _outcome.BitsEmbedded;
        var stego = _stego;
        StegoPayloadResult? payload = null;
        try
        {
            payload = await Task.Run(() => AppState.Watermarking.ExtractPayload(stego, bits));
        }
        finally
        {
            _verifying = false;
            VerifyProgress.Visibility = Visibility.Collapsed;
            VerifyIcon.Visibility = Visibility.Visible;
            UpdateFabStates();
            UpdateResultActionButtons();
        }

        var ok = false;
        if (_audioPayloadMode)
        {
            if (_payloadAudio is null || payload?.Audio is null)
            {
                ok = false;
            }
            else
            {
                var expected = PayloadEnvelope.DecodeAudioBody(
                    PayloadEnvelope.EncodeAudioBody(_payloadAudio));
                var recovered = payload.Audio;
                ok = recovered.SampleRate == expected.SampleRate &&
                     recovered.Samples.Length == expected.Samples.Length &&
                     recovered.Samples.AsSpan().SequenceEqual(expected.Samples);
            }
        }
        else
        {
            ok = payload?.Text is not null && payload.Text == original;
        }

        if (!ok && (payload?.Text is null or "" && payload?.Audio is null))
        {
            VerifyText.Text = s.VerifyEmpty;
            VerifyBanner.Background = new SolidColorBrush(Color.FromArgb(40, 179, 38, 30));
            VerifyBannerIcon.Text = "\uE783";
            VerifyText.Foreground = (Brush)FindResource("ErrorBrush");
        }
        else if (ok)
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
