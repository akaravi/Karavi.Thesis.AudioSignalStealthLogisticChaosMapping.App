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
    private readonly PlaybackHub _hub = PlaybackHub.Instance;
    private double[] _eqBands = new double[SpectrumAnalyzer.BandCount];
    private WavFile? _cover;
    private WavFile? _stego;
    private WatermarkOutcome? _outcome;
    private WavFile? _payloadAudio;
    private byte[]? _payloadImageBytes;
    private WavFile? _recoveredAudio;
    private byte[]? _recoveredImageBytes;
    private string? _recoveredText;
    private bool _audioPayloadMode;
    private bool _imagePayloadMode;
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
        foreach (var id in PlaybackHub.AbSessions)
        {
            _hub.Engine(id).SpectrumBands += OnSpectrumBands;
            _hub.Engine(id).PlaybackStateChanged += UpdatePlaybackButtons;
        }
        _hub.Engine(PlaybackSessionId.EmbedPayloadOriginal).PlaybackStateChanged += UpdateRecoveredPlayButton;
        _hub.Engine(PlaybackSessionId.EmbedPayloadRecovered).PlaybackStateChanged += UpdateRecoveredPlayButton;
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
        PayloadModeImage.Content = s.EmbedPayloadImageTab;
        MessageLabel.Text = s.TextHint;
        MessageTextBox.SetValue(ToolTipService.ToolTipProperty, s.TextHint);
        var useFixed = AppState.Settings.DefaultFixedMessageBitLimit;
        AudioPayloadHint.Text = useFixed ? s.EmbedPayloadAudioHint : s.EmbedPayloadAudioHintDynamic;
        ClearPayloadAudioLabel.Text = s.ClearPayloadAudio;
        ImagePayloadHint.Text = useFixed ? s.EmbedPayloadImageHint : s.EmbedPayloadImageHintDynamic;
        PickPayloadImageLabel.Text = s.PickPayloadImage;
        ClearPayloadImageLabel.Text = s.ClearPayloadImage;
        AudioSourceOrLabel.Text = s.AudioSourceOr;
        EqualizerTitle.Text = s.AudioEqualizer;
        RefreshRecordButtonLabels();
        LoadFileBtn.Label = s.LoadAudioFile;
        LoadFileBtn.RefreshVisual();
        ToolTipService.SetToolTip(PauseCoverButton, s.Pause);
        ToolTipService.SetToolTip(StopCoverButton, s.StopPlayback);
        ToolTipService.SetToolTip(PauseStegoButton, s.Pause);
        ToolTipService.SetToolTip(StopStegoButton, s.StopPlayback);
        ToolTipService.SetToolTip(CopyMessageButton, s.Copy);
        ToolTipService.SetToolTip(VerifyButton, s.Verify);
        ToolTipService.SetToolTip(SaveButton, s.SaveStego);
        ToolTipService.SetToolTip(ShareButton, s.ShareStego);
        ToolTipService.SetToolTip(PlayCoverButton, s.PlayOriginalCover);
        ToolTipService.SetToolTip(PlayStegoButton, s.PlayStegoAudio);
        ToolTipService.SetToolTip(PlayOriginalPayloadButton, s.PlayOriginalPayloadAudio);
        ToolTipService.SetToolTip(PlayRecoveredButton, s.PlayExtractedAudio);
        ToolTipService.SetToolTip(CopyOriginalButton, s.Copy);
        ToolTipService.SetToolTip(CopyRecoveredButton, s.Copy);
        ToolTipService.SetToolTip(SaveRecoveredButton, s.SaveExtractedAudio);
        ResultSubtitle.Text = s.OperationSuccessSubtitle;
        AnalysisSectionTitle.Text = s.AnalysisSectionTitle;
        AbListenTitle.Text = s.VerifyAbListenTitle;
        AbListenOriginalSideTitle.Text = s.AbListenOriginalShort;
        AbListenStegoSideTitle.Text = s.AbListenStegoShort;
        RecoveredPayloadTitle.Text = s.VerifyRecoveredTitle;
        OriginalPayloadHeading.Text = s.OriginalHiddenPayload;
        RecoveredPayloadHeading.Text = s.RecoveredPayloadLabel;
        MetricsTapHint.Text = s.MetricHelpTapHint;
        ToolTipService.SetToolTip(NewEmbedFab, s.EmbedNew);
        ToolTipService.SetToolTip(HelpFab, s.HelpTooltip);
        UpdateFabStates();
        UpdateMessageBitCounter();
        UpdateAudioPayloadUi();
        UpdateImagePayloadUi();
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
        _imagePayloadMode = PayloadModeImage.IsChecked == true;
        TextPayloadPanel.Visibility = (!_audioPayloadMode && !_imagePayloadMode)
            ? Visibility.Visible
            : Visibility.Collapsed;
        AudioPayloadPanel.Visibility = _audioPayloadMode ? Visibility.Visible : Visibility.Collapsed;
        ImagePayloadPanel.Visibility = _imagePayloadMode ? Visibility.Visible : Visibility.Collapsed;
        if (!_audioPayloadMode)
            _payloadAudio = null;
        if (!_imagePayloadMode)
            ClearImagePreview();
        RefreshRecordButtonLabels();
        UpdateAudioPayloadUi();
        UpdateImagePayloadUi();
    }

    private void ClearPayloadAudio_Click(object sender, RoutedEventArgs e)
    {
        _payloadAudio = null;
        StatusText.Text = string.Empty;
        UpdateAudioPayloadUi();
        RefreshRecordButtonLabels();
    }

    private void ClearPayloadImage_Click(object sender, RoutedEventArgs e)
    {
        ClearImagePreview();
        StatusText.Text = string.Empty;
        UpdateImagePayloadUi();
    }

    private void ClearImagePreview()
    {
        _payloadImageBytes = null;
        PayloadImagePreview.Source = null;
        PayloadImagePreview.Visibility = Visibility.Collapsed;
    }

    private void PickPayloadImage_Click(object sender, RoutedEventArgs e)
    {
        if (_busy || _capture.IsRecording) return;
        var s = ThemeManager.Strings;
        var dlg = new OpenFileDialog
        {
            Filter = "Images|*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.webp|All files|*.*",
        };
        if (dlg.ShowDialog() != true) return;
        try
        {
            var source = File.ReadAllBytes(dlg.FileName);
            int? budget = AppState.Settings.DefaultFixedMessageBitLimit
                ? AppConfig.Current.DefaultFixedMessageBitLength
                : null;
            var compressed = PayloadImageCodec.CompressForEmbed(source, budget);
            _payloadImageBytes = compressed;
            using var ms = new MemoryStream(compressed);
            var bmp = new System.Windows.Media.Imaging.BitmapImage();
            bmp.BeginInit();
            bmp.CacheOption = System.Windows.Media.Imaging.BitmapCacheOption.OnLoad;
            bmp.StreamSource = ms;
            bmp.EndInit();
            bmp.Freeze();
            PayloadImagePreview.Source = bmp;
            PayloadImagePreview.Visibility = Visibility.Visible;
            StatusText.Text = s.PayloadImageReady;
            UpdateImagePayloadUi();
        }
        catch (InvalidOperationException)
        {
            ShowEmbedWarning(
                AppState.Settings.DefaultFixedMessageBitLimit
                    ? s.ErrorPayloadImageBudget
                    : s.ErrorPayloadImageDecode);
        }
        catch (Exception)
        {
            ShowEmbedWarning(s.ErrorPayloadImageDecode);
        }
    }

    private void UpdateAudioPayloadUi()
    {
        var s = ThemeManager.Strings;
        var useFixed = AppState.Settings.DefaultFixedMessageBitLimit;
        var budget = AppConfig.Current.DefaultFixedMessageBitLength;
        if (_payloadAudio is null)
        {
            if (useFixed)
            {
                AudioPayloadBudget.Visibility = Visibility.Visible;
                AudioPayloadBudget.Text = s.PayloadAudioBudgetLabel(0, budget);
            }
            else
            {
                AudioPayloadBudget.Text = string.Empty;
                AudioPayloadBudget.Visibility = Visibility.Collapsed;
            }
            ClearPayloadAudioBtn.Visibility = Visibility.Collapsed;
        }
        else
        {
            var used = PayloadEnvelope.BitLengthForAudio(_payloadAudio);
            AudioPayloadBudget.Visibility = Visibility.Visible;
            if (useFixed)
                AudioPayloadBudget.Text = s.PayloadAudioBudgetLabel(used, budget);
            else
                AudioPayloadBudget.Text =
                    $"{s.PayloadAudioBitsRequired(used)}\n{s.CoverRecordNeedHint(used, CoverNeedSecondsForBits(used))}";
            ClearPayloadAudioBtn.Visibility = Visibility.Visible;
        }
    }

    private void UpdateImagePayloadUi()
    {
        var s = ThemeManager.Strings;
        var useFixed = AppState.Settings.DefaultFixedMessageBitLimit;
        var budget = AppConfig.Current.DefaultFixedMessageBitLength;
        if (_payloadImageBytes is null)
        {
            if (useFixed)
            {
                ImagePayloadBudget.Visibility = Visibility.Visible;
                ImagePayloadBudget.Text = s.PayloadImageBudgetLabel(0, budget);
            }
            else
            {
                ImagePayloadBudget.Text = string.Empty;
                ImagePayloadBudget.Visibility = Visibility.Collapsed;
            }
            ClearPayloadImageBtn.Visibility = Visibility.Collapsed;
        }
        else
        {
            var used = PayloadEnvelope.BitLengthForImage(_payloadImageBytes);
            ImagePayloadBudget.Visibility = Visibility.Visible;
            if (useFixed)
                ImagePayloadBudget.Text = s.PayloadImageBudgetLabel(used, budget);
            else
                ImagePayloadBudget.Text =
                    $"{s.PayloadImageBitsRequired(used)}\n{s.CoverRecordNeedHint(used, CoverNeedSecondsForBits(used))}";
            ClearPayloadImageBtn.Visibility = Visibility.Visible;
        }
    }

    private static int CoverNeedSecondsForBits(int bits)
    {
        var seconds = (int)Math.Ceiling(
            CoverRecordBudget.RemainingFromSamples(
                0, bits, CoverRecordBudget.CoverSampleRate).TotalSeconds);
        return Math.Clamp(seconds, 1, 3600);
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
        CopyMessageButton.IsEnabled = enabled && !_audioPayloadMode && !_imagePayloadMode &&
                                      !string.IsNullOrWhiteSpace(MessageTextBox.Text);
        CopyMessageButton.Visibility = (!_audioPayloadMode && !_imagePayloadMode)
            ? Visibility.Visible
            : Visibility.Collapsed;
        if (!enabled || _verifying)
        {
            PauseCoverButton.Visibility = Visibility.Collapsed;
            StopCoverButton.Visibility = Visibility.Collapsed;
            PauseStegoButton.Visibility = Visibility.Collapsed;
            StopStegoButton.Visibility = Visibility.Collapsed;
            PlayCoverButton.IsEnabled = false;
            PlayStegoButton.IsEnabled = false;
        }
        else
            UpdatePlaybackButtons();
    }

    private void RecoveredCompareGrid_SizeChanged(object sender, SizeChangedEventArgs e)
    {
        const double breakpoint = 560;
        var narrow = e.NewSize.Width > 0 && e.NewSize.Width < breakpoint;
        if (narrow)
        {
            RecoveredCompareColGap.Width = new GridLength(0);
            RecoveredCompareCol1.Width = new GridLength(0);
            RecoveredCompareRowGap.Height = new GridLength(16);
            Grid.SetColumn(OriginalPayloadColumn, 0);
            Grid.SetRow(OriginalPayloadColumn, 0);
            Grid.SetColumn(RecoveredPayloadColumn, 0);
            Grid.SetRow(RecoveredPayloadColumn, 2);
        }
        else
        {
            RecoveredCompareColGap.Width = new GridLength(16);
            RecoveredCompareCol1.Width = new GridLength(1, GridUnitType.Star);
            RecoveredCompareRowGap.Height = new GridLength(0);
            Grid.SetColumn(OriginalPayloadColumn, 0);
            Grid.SetRow(OriginalPayloadColumn, 0);
            Grid.SetColumn(RecoveredPayloadColumn, 2);
            Grid.SetRow(RecoveredPayloadColumn, 0);
        }
    }

    private void AbListenCompareGrid_SizeChanged(object sender, SizeChangedEventArgs e)
    {
        const double breakpoint = 560;
        var narrow = e.NewSize.Width > 0 && e.NewSize.Width < breakpoint;
        if (narrow)
        {
            AbListenColGap.Width = new GridLength(0);
            AbListenCol1.Width = new GridLength(0);
            AbListenRowGap.Height = new GridLength(10);
            Grid.SetColumn(AbListenOriginalCard, 0);
            Grid.SetRow(AbListenOriginalCard, 0);
            Grid.SetColumn(AbListenStegoCard, 0);
            Grid.SetRow(AbListenStegoCard, 2);
        }
        else
        {
            AbListenColGap.Width = new GridLength(10);
            AbListenCol1.Width = new GridLength(1, GridUnitType.Star);
            AbListenRowGap.Height = new GridLength(0);
            Grid.SetColumn(AbListenOriginalCard, 0);
            Grid.SetRow(AbListenOriginalCard, 0);
            Grid.SetColumn(AbListenStegoCard, 2);
            Grid.SetRow(AbListenStegoCard, 0);
        }
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

        try { _hub.StopAbSessions(); }
        catch { /* ignore */ }
        try { _hub.Stop(PlaybackSessionId.EmbedPayloadOriginal); _hub.Stop(PlaybackSessionId.EmbedPayloadRecovered); }
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
        CapacityExceededException.TryParse(message, out _) ||
        message.Contains("too long", StringComparison.OrdinalIgnoreCase) ||
        message.Contains("Message too long", StringComparison.Ordinal) ||
        message.Contains("capacity exceeded", StringComparison.OrdinalIgnoreCase);

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
        SetProcessBusy(false);
        RecordBtn.IsEnabled = true;
        LoadFileBtn.IsEnabled = true;
        RecordBtn.IsRecording = false;
        Equalizer.IsActive = false;
        MessageTextBox.IsEnabled = true;
        _busy = false;
        StatusText.Text = string.Empty;
        UpdateFabStates();
    }

    private void SetProcessBusy(bool busy, string? message = null)
    {
        BusyBar.Visibility = Visibility.Collapsed;
        if (Window.GetWindow(this) is MainWindow main)
            main.SetGlobalBusy(busy, message);
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
        else if (used <= 0)
            MessageBitsCounter.Text = s.MessageBitsUsed(used);
        else
            MessageBitsCounter.Text =
                $"{s.MessageBitsUsed(used)}\n{s.CoverRecordNeedHint(used, CoverNeedSecondsForBits(used))}";
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
        Equalizer.IsActive = _capture.IsRecording || _hub.IsPlaying(PlaybackSessionId.EmbedCover) || _hub.IsPlaying(PlaybackSessionId.EmbedStego) || _hub.HasSource(PlaybackSessionId.EmbedCover) || _hub.HasSource(PlaybackSessionId.EmbedStego);
    }

    private void UpdatePlaybackButtons()
    {
        if (!Dispatcher.CheckAccess())
        {
            Dispatcher.BeginInvoke(UpdatePlaybackButtons);
            return;
        }
        var coverPlaying = _hub.IsPlaying(PlaybackSessionId.EmbedCover);
        var stegoPlaying = _hub.IsPlaying(PlaybackSessionId.EmbedStego);
        var coverPaused = _hub.IsPaused(PlaybackSessionId.EmbedCover);
        var stegoPaused = _hub.IsPaused(PlaybackSessionId.EmbedStego);
        var coverTransport = coverPlaying || coverPaused;
        var stegoTransport = stegoPlaying || stegoPaused;
        var canInteract = !_verifying && _stego is not null;
        PauseCoverButton.Visibility = canInteract && coverTransport ? Visibility.Visible : Visibility.Collapsed;
        StopCoverButton.Visibility = canInteract && coverTransport ? Visibility.Visible : Visibility.Collapsed;
        PauseStegoButton.Visibility = canInteract && stegoTransport ? Visibility.Visible : Visibility.Collapsed;
        StopStegoButton.Visibility = canInteract && stegoTransport ? Visibility.Visible : Visibility.Collapsed;
        PauseCoverButton.IsEnabled = canInteract && coverPlaying;
        PauseStegoButton.IsEnabled = canInteract && stegoPlaying;
        StopCoverButton.IsEnabled = canInteract && coverTransport;
        StopStegoButton.IsEnabled = canInteract && stegoTransport;
        PlayCoverButton.IsEnabled = canInteract && _cover is not null && (!coverPlaying || coverPaused);
        PlayStegoButton.IsEnabled = canInteract && (!stegoPlaying || stegoPaused);
        AbListenOriginalCard.BorderThickness = new Thickness(coverPlaying ? 2 : 1);
        AbListenStegoCard.BorderThickness = new Thickness(stegoPlaying ? 2 : 1);
        AbListenOriginalCard.BorderBrush = coverPlaying
            ? (Brush)FindResource("PrimaryBrush")
            : (Brush)FindResource("BorderBrush");
        AbListenStegoCard.BorderBrush = (Brush)FindResource("PrimaryBrush");
    }

    private async void RecordBtn_Click(object sender, RoutedEventArgs e)
    {
        if (_busy) return;
        var s = ThemeManager.Strings;

        if (_capture.IsRecording)
        {
            if (!_recordingPayload && !IsCoverRecordMinSatisfied())
            {
                var remain = CoverRecordRemainingSeconds();
                StatusText.Text = s.RecordingTooShort(remain);
                UpdateCoverMinProgressUi();
                return;
            }

            _busy = true;
            StatusText.Text = s.Processing;
            SetProcessBusy(true, s.Processing);
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
                    if (AppState.Settings.DefaultFixedMessageBitLimit && needed > budget)
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
        else if (_imagePayloadMode)
        {
            if (_payloadImageBytes is null)
            {
                ShowEmbedWarning(s.ErrorEmptyPayloadImage);
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
        _recordTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(200) };
        _recordTimer.Tick += (_, _) =>
        {
            Equalizer.RecordingElapsed = DateTime.UtcNow - _recordStartUtc;
            if (_recordingPayload &&
                AppState.Settings.DefaultFixedMessageBitLimit &&
                IsPayloadCapacityFull())
            {
                _recordTimer?.Stop();
                // Auto-stop when fixed capacity is filled (mirrors Flutter).
                _ = Dispatcher.BeginInvoke(new Action(() =>
                {
                    if (_capture.IsRecording && _recordingPayload)
                        RecordBtn_Click(RecordBtn, new RoutedEventArgs());
                }));
                return;
            }
            UpdateCoverMinProgressUi();
        };
        _recordTimer.Start();
        UpdateCoverMinProgressUi();
    }

    private void StopRecordTimer()
    {
        _recordTimer?.Stop();
        _recordTimer = null;
        Equalizer.RecordingElapsed = null;
        CoverMinProgressPanel.Visibility = Visibility.Collapsed;
        CoverMinProgressBar.Value = 0;
        CoverMinProgressText.Text = string.Empty;
    }

    private int? PayloadCapacityBudgetBits()
    {
        if (!_recordingPayload) return null;
        if (!AppState.Settings.DefaultFixedMessageBitLimit) return null;
        var bits = AppConfig.Current.DefaultFixedMessageBitLength;
        return bits > 0 ? bits : null;
    }

    private bool IsPayloadCapacityFull()
    {
        var budget = PayloadCapacityBudgetBits();
        if (budget is null) return false;
        var maxSamples = PayloadAudioDefaults.MaxPcmSamplesForBitBudget(budget.Value);
        return maxSamples > 0 && _capture.BufferedMonoSampleCount >= maxSamples;
    }

    private int? CoverRequiredBits()
    {
        if (_recordingPayload) return null;
        if (AppState.Settings.DefaultFixedMessageBitLimit)
        {
            var bits = AppConfig.Current.DefaultFixedMessageBitLength;
            return bits > 0 ? bits : null;
        }

        if (_payloadAudio is not null)
        {
            var n = PayloadEnvelope.BitLengthForAudio(_payloadAudio);
            return n > 0 ? n : null;
        }

        if (_payloadImageBytes is not null)
        {
            var n = PayloadEnvelope.BitLengthForImage(_payloadImageBytes);
            return n > 0 ? n : null;
        }

        if (PayloadModeText.IsChecked == true)
        {
            var text = MessageTextBox.Text.Trim();
            if (string.IsNullOrEmpty(text)) return null;
            var n = PayloadEnvelope.BitLengthForText(text);
            return n > 0 ? n : null;
        }

        return null;
    }

    private bool IsCoverRecordMinSatisfied()
    {
        var bits = CoverRequiredBits();
        if (bits is null) return true;
        return CoverRecordBudget.SamplesSatisfied(_capture.BufferedMonoSampleCount, bits.Value);
    }

    private int CoverRecordRemainingSeconds()
    {
        var bits = CoverRequiredBits();
        if (bits is null) return 0;
        var rate = _capture.SampleRate > 0 ? _capture.SampleRate : CoverRecordBudget.CoverSampleRate;
        return Math.Max(1, (int)Math.Ceiling(
            CoverRecordBudget.RemainingFromSamples(
                _capture.BufferedMonoSampleCount, bits.Value, rate).TotalSeconds));
    }

    private int PayloadCapacityRemainingSeconds()
    {
        var budget = PayloadCapacityBudgetBits();
        if (budget is null) return 0;
        var maxSamples = PayloadAudioDefaults.MaxPcmSamplesForBitBudget(budget.Value);
        var need = maxSamples - _capture.BufferedMonoSampleCount;
        if (need <= 0) return 0;
        var rate = _capture.SampleRate > 0 ? _capture.SampleRate : PayloadAudioDefaults.SampleRate;
        return Math.Max(1, (int)Math.Ceiling(need / (double)rate));
    }

    private void UpdateCoverMinProgressUi()
    {
        if (!Dispatcher.CheckAccess())
        {
            Dispatcher.BeginInvoke(UpdateCoverMinProgressUi);
            return;
        }

        var s = ThemeManager.Strings;
        var buffered = _capture.BufferedMonoSampleCount;

        // Payload (secret) voice: capacity fill bar when fixed budget is on.
        var payloadBudget = PayloadCapacityBudgetBits();
        if (_capture.IsRecording && _recordingPayload && payloadBudget is not null)
        {
            var maxSamples = PayloadAudioDefaults.MaxPcmSamplesForBitBudget(payloadBudget.Value);
            var progress = maxSamples <= 0
                ? 1.0
                : Math.Clamp(buffered / (double)maxSamples, 0, 1);
            CoverMinProgressPanel.Visibility = Visibility.Visible;
            CoverMinProgressBar.Value = progress;
            if (IsPayloadCapacityFull())
            {
                CoverMinProgressText.Text = s.PayloadRecordCapacityFull;
                StatusText.Text = s.PayloadRecordCapacityFull;
            }
            else
            {
                var remain = PayloadCapacityRemainingSeconds();
                CoverMinProgressText.Text =
                    $"{s.PayloadRecordCapacityProgress} {s.PayloadRecordCapacityRemaining(remain)}";
                StatusText.Text = CoverMinProgressText.Text;
            }
            return;
        }

        var bits = CoverRequiredBits();
        if (!_capture.IsRecording || _recordingPayload || bits is null)
        {
            CoverMinProgressPanel.Visibility = Visibility.Collapsed;
            return;
        }

        var coverProgress = CoverRecordBudget.ProgressFromSamples(buffered, bits.Value);
        CoverMinProgressPanel.Visibility = Visibility.Visible;
        CoverMinProgressBar.Value = coverProgress;
        if (CoverRecordBudget.SamplesSatisfied(buffered, bits.Value))
        {
            CoverMinProgressText.Text = s.RecordingMinReached;
            StatusText.Text = s.RecordingMinReached;
        }
        else
        {
            var remain = CoverRecordRemainingSeconds();
            CoverMinProgressText.Text =
                $"{s.RecordingMinProgress} {s.RecordingMinRemaining(remain)}";
            StatusText.Text = CoverMinProgressText.Text;
        }
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
        else if (_imagePayloadMode)
        {
            if (_payloadImageBytes is null)
            {
                ShowEmbedWarning(s.ErrorEmptyPayloadImage);
                return;
            }
        }
        else if (string.IsNullOrEmpty(messageText))
        {
            ShowEmbedWarning(s.ErrorEmpty);
            return;
        }

        _busy = true;
        StatusText.Text = s.Processing;
        SetProcessBusy(true, s.Processing);
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
                var available = cover.ToMono().Samples.Length;
                if (bits.Length > available)
                {
                    ShowEmbedWarning(s.ErrorCapacityExceeded(bits.Length, available));
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
        else if (_imagePayloadMode)
        {
            if (_payloadImageBytes is null)
            {
                ShowEmbedWarning(s.ErrorEmptyPayloadImage);
                return;
            }
            try
            {
                var bits = PayloadEnvelope.PackImageBits(_payloadImageBytes, fixedBitLength: fixedLen);
                var available = cover.ToMono().Samples.Length;
                if (bits.Length > available)
                {
                    ShowEmbedWarning(s.ErrorCapacityExceeded(bits.Length, available));
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
                ShowEmbedWarning(s.ErrorPayloadImageBudget);
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

            var available = cover.ToMono().Samples.Length;
            var required = useFixedLen
                ? AppConfig.Current.DefaultFixedMessageBitLength
                : PayloadEnvelope.BitLengthForText(messageText);
            if (required > available)
            {
                ShowEmbedWarning(s.ErrorCapacityExceeded(required, available));
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
            if (CapacityExceededException.TryParse(error, out var capacityEx) && capacityEx is not null)
                ShowEmbedWarning(s.ErrorCapacityExceeded(capacityEx.NeededBits, capacityEx.AvailableBits));
            else if (IsEmbedCapacityError(error))
                ShowEmbedWarning(s.ErrorCapacityExceeded(
                    PayloadEnvelope.BitLengthForText(messageText),
                    cover.ToMono().Samples.Length));
            else if (IsEmbedIntegrityError(error))
                ShowEmbedWarning(s.ErrorEmbedIntegrity);
            else
                StatusText.Text = error;
        }
        else if (outcome is not null)
        {
            await ShowResultAsync(outcome, cover);
            if (loadedFileName is not null)
                StatusText.Text = s.AudioFileLoaded(loadedFileName);
        }
    }

    private void ResetForNewEmbed()
    {
        try { _hub.StopAbSessions(); }
        catch { /* ignore */ }
        try { _hub.Stop(PlaybackSessionId.EmbedPayloadOriginal); _hub.Stop(PlaybackSessionId.EmbedPayloadRecovered); }
        catch { /* ignore */ }
        _cover = null;
        _stego = null;
        _outcome = null;
        _payloadAudio = null;
        ClearImagePreview();
        ClearRecoveredPayloadUi();
        _recordingPayload = false;
        _audioPayloadMode = false;
        _imagePayloadMode = false;
        PayloadModeText.IsChecked = true;
        PayloadModeAudio.IsChecked = false;
        PayloadModeImage.IsChecked = false;
        TextPayloadPanel.Visibility = Visibility.Visible;
        AudioPayloadPanel.Visibility = Visibility.Collapsed;
        ImagePayloadPanel.Visibility = Visibility.Collapsed;
        ResultPanel.Visibility = Visibility.Collapsed;
        VerifyBanner.Visibility = Visibility.Collapsed;
        AbListenPanel.Visibility = Visibility.Collapsed;
        
        EmbedInputPanel.Visibility = Visibility.Visible;
        MessageTextBox.IsEnabled = true;
        StatusText.Text = string.Empty;
        Equalizer.SetBands(new double[SpectrumAnalyzer.BandCount]);
        UpdateAudioPayloadUi();
        UpdateImagePayloadUi();
        RefreshRecordButtonLabels();
        UpdatePlaybackButtons();
        UpdateFabStates();
    }

    private async Task ShowResultAsync(WatermarkOutcome outcome, WavFile? cover)
    {
        var s = ThemeManager.Strings;
        _outcome = outcome;
        _cover = cover;
        _stego = outcome.Stego;
        StatusText.Text = string.Empty;
        EmbedInputPanel.Visibility = Visibility.Collapsed;

        ResultPanel.Visibility = Visibility.Visible;
        ResultTitle.Text = s.OperationSuccess;
        ResultSubtitle.Text = s.OperationSuccessSubtitle;
        AnalysisSectionTitle.Text = s.AnalysisSectionTitle;
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
        AbListenPanel.Visibility = cover is not null ? Visibility.Visible : Visibility.Collapsed;
        
        UpdatePlaybackButtons();
        UpdateResultActionButtons();
        await ExtractAndShowRecoveredAsync(autoAfterEmbed: true);
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
            s.OperationSuccess,
            s.EmbedCompleteTitle,
            MessageBoxButton.OK,
            MessageBoxImage.Information);
    }

    private void PlayCoverButton_Click(object sender, RoutedEventArgs e)
    {
        if (_cover is null) return;
        try { _hub.PlayIfNotPlaying(PlaybackSessionId.EmbedCover, _cover); }
        catch (Exception ex) { StatusText.Text = ex.Message; }
    }

    private void PlayStegoButton_Click(object sender, RoutedEventArgs e)
    {
        if (_stego is null) return;
        try { _hub.PlayIfNotPlaying(PlaybackSessionId.EmbedStego, _stego); }
        catch (Exception ex) { StatusText.Text = ex.Message; }
    }

    private void PauseCoverButton_Click(object sender, RoutedEventArgs e)
    {
        try { _hub.Pause(PlaybackSessionId.EmbedCover); }
        catch (Exception ex) { StatusText.Text = ex.Message; }
    }

    private void PauseStegoButton_Click(object sender, RoutedEventArgs e)
    {
        try { _hub.Pause(PlaybackSessionId.EmbedStego); }
        catch (Exception ex) { StatusText.Text = ex.Message; }
    }

    private void StopCoverButton_Click(object sender, RoutedEventArgs e)
    {
        try { _hub.Stop(PlaybackSessionId.EmbedCover); }
        catch (Exception ex) { StatusText.Text = ex.Message; }
    }

    private void StopStegoButton_Click(object sender, RoutedEventArgs e)
    {
        try { _hub.Stop(PlaybackSessionId.EmbedStego); }
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
        await ExtractAndShowRecoveredAsync(autoAfterEmbed: false);
    }

    private async Task ExtractAndShowRecoveredAsync(bool autoAfterEmbed)
    {
        if (_stego is null || _outcome is null || _verifying) return;
        var s = ThemeManager.Strings;
        _verifying = true;
        UpdateFabStates();
        UpdateResultActionButtons();
        if (!autoAfterEmbed)
            SetProcessBusy(true, s.Verifying);
        try { _hub.Stop(PlaybackSessionId.EmbedPayloadOriginal); _hub.Stop(PlaybackSessionId.EmbedPayloadRecovered); }
        catch { /* ignore */ }
        ClearRecoveredPayloadUi();

        if (!autoAfterEmbed)
        {
            VerifyProgress.Visibility = Visibility.Visible;
            VerifyIcon.Visibility = Visibility.Collapsed;
            VerifyBanner.Visibility = Visibility.Visible;
            VerifyText.Text = s.Verifying;
            VerifyBanner.Background = (Brush)FindResource("SurfaceVariantBrush");
            VerifyBannerIcon.Text = "\uE121";
            VerifyText.Foreground = (Brush)FindResource("TextBrush");
        }

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
            SetProcessBusy(false);
            VerifyProgress.Visibility = Visibility.Collapsed;
            VerifyIcon.Visibility = Visibility.Visible;
            UpdateFabStates();
            UpdateResultActionButtons();
        }

        var ok = false;
        if (_audioPayloadMode)
        {
            if (_payloadAudio is null || payload?.Audio is null)
                ok = false;
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
        else if (_imagePayloadMode)
        {
            ok = _payloadImageBytes is not null &&
                 payload?.ImageBytes is not null &&
                 _payloadImageBytes.AsSpan().SequenceEqual(payload.ImageBytes);
        }
        else
        {
            ok = payload?.Text is not null && payload.Text == original;
        }

        VerifyBanner.Visibility = Visibility.Visible;
        if (!ok && payload?.Text is null or "" && payload?.Audio is null && payload?.ImageBytes is null)
        {
            VerifyText.Text = s.VerifyEmpty;
            VerifyBanner.Background = new SolidColorBrush(Color.FromArgb(40, 179, 38, 30));
            VerifyBannerIcon.Text = "\uE783";
            VerifyText.Foreground = (Brush)FindResource("ErrorBrush");
            return;
        }

        if (ok)
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

        if (payload is not null)
            ShowRecoveredPayload(payload);
    }

    private void ClearRecoveredPayloadUi()
    {
        _recoveredAudio = null;
        _recoveredImageBytes = null;
        _recoveredText = null;
        
        RecoveredPayloadPanel.Visibility = Visibility.Collapsed;
        OriginalTextBox.Visibility = Visibility.Collapsed;
        OriginalTextBox.Text = string.Empty;
        RecoveredTextBox.Visibility = Visibility.Collapsed;
        RecoveredTextBox.Text = string.Empty;
        OriginalImage.Source = null;
        OriginalImage.Visibility = Visibility.Collapsed;
        RecoveredImage.Source = null;
        RecoveredImage.Visibility = Visibility.Collapsed;
        PlayOriginalPayloadButton.Visibility = Visibility.Collapsed;
        PlayRecoveredButton.Visibility = Visibility.Collapsed;
        SaveRecoveredButton.Visibility = Visibility.Collapsed;
        CopyOriginalButton.Visibility = Visibility.Collapsed;
        CopyRecoveredButton.Visibility = Visibility.Collapsed;
    }

    private static System.Windows.Media.Imaging.BitmapImage? LoadBitmap(byte[] bytes)
    {
        try
        {
            using var ms = new MemoryStream(bytes);
            var bmp = new System.Windows.Media.Imaging.BitmapImage();
            bmp.BeginInit();
            bmp.CacheOption = System.Windows.Media.Imaging.BitmapCacheOption.OnLoad;
            bmp.StreamSource = ms;
            bmp.EndInit();
            bmp.Freeze();
            return bmp;
        }
        catch
        {
            return null;
        }
    }

    private void ShowRecoveredPayload(StegoPayloadResult payload)
    {
        var s = ThemeManager.Strings;
        RecoveredPayloadTitle.Text = s.VerifyRecoveredTitle;
        OriginalPayloadHeading.Text = s.OriginalHiddenPayload;
        RecoveredPayloadHeading.Text = s.RecoveredPayloadLabel;
        RecoveredPayloadPanel.Visibility = Visibility.Visible;
        

        if (payload.ImageBytes is not null)
        {
            _recoveredImageBytes = payload.ImageBytes;
            _recoveredAudio = null;
            _recoveredText = null;
            OriginalTextBox.Visibility = Visibility.Collapsed;
            RecoveredTextBox.Visibility = Visibility.Collapsed;
            PlayOriginalPayloadButton.Visibility = Visibility.Collapsed;
            PlayRecoveredButton.Visibility = Visibility.Collapsed;
            CopyOriginalButton.Visibility = Visibility.Collapsed;
            CopyRecoveredButton.Visibility = Visibility.Collapsed;
            SaveRecoveredButton.Visibility = Visibility.Visible;
            ToolTipService.SetToolTip(SaveRecoveredButton, s.SaveExtractedImage);

            OriginalImage.Source = _payloadImageBytes is not null
                ? LoadBitmap(_payloadImageBytes)
                : null;
            OriginalImage.Visibility = OriginalImage.Source is not null
                ? Visibility.Visible
                : Visibility.Collapsed;
            RecoveredImage.Source = LoadBitmap(payload.ImageBytes);
            RecoveredImage.Visibility = RecoveredImage.Source is not null
                ? Visibility.Visible
                : Visibility.Collapsed;
            return;
        }

        if (payload.Audio is not null)
        {
            _recoveredAudio = payload.Audio;
            _recoveredImageBytes = null;
            _recoveredText = null;
            OriginalTextBox.Visibility = Visibility.Collapsed;
            RecoveredTextBox.Visibility = Visibility.Collapsed;
            OriginalImage.Visibility = Visibility.Collapsed;
            RecoveredImage.Visibility = Visibility.Collapsed;
            CopyOriginalButton.Visibility = Visibility.Collapsed;
            CopyRecoveredButton.Visibility = Visibility.Collapsed;
            PlayOriginalPayloadButton.Visibility =
                _payloadAudio is not null ? Visibility.Visible : Visibility.Collapsed;
            PlayRecoveredButton.Visibility = Visibility.Visible;
            SaveRecoveredButton.Visibility = Visibility.Visible;
            ToolTipService.SetToolTip(SaveRecoveredButton, s.SaveExtractedAudio);
            ToolTipService.SetToolTip(PlayOriginalPayloadButton, s.PlayOriginalPayloadAudio);
            ToolTipService.SetToolTip(PlayRecoveredButton, s.PlayExtractedAudio);
            UpdateRecoveredPlayButton();
            return;
        }

        _recoveredText = payload.Text ?? string.Empty;
        _recoveredAudio = null;
        _recoveredImageBytes = null;
        OriginalImage.Visibility = Visibility.Collapsed;
        RecoveredImage.Visibility = Visibility.Collapsed;
        PlayOriginalPayloadButton.Visibility = Visibility.Collapsed;
        PlayRecoveredButton.Visibility = Visibility.Collapsed;
        SaveRecoveredButton.Visibility = Visibility.Collapsed;

        var originalText = MessageTextBox.Text ?? string.Empty;
        OriginalTextBox.Visibility = Visibility.Visible;
        OriginalTextBox.Text = originalText;
        ContentTextDirectionHelper.ApplyTo(OriginalTextBox, originalText);
        CopyOriginalButton.Visibility = Visibility.Visible;
        ToolTipService.SetToolTip(CopyOriginalButton, s.Copy);

        RecoveredTextBox.Visibility = Visibility.Visible;
        RecoveredTextBox.Text = _recoveredText;
        ContentTextDirectionHelper.ApplyTo(RecoveredTextBox, _recoveredText);
        CopyRecoveredButton.Visibility = Visibility.Visible;
        ToolTipService.SetToolTip(CopyRecoveredButton, s.Copy);
    }

    private void UpdateRecoveredPlayButton()
    {
        if (!Dispatcher.CheckAccess())
        {
            Dispatcher.BeginInvoke(UpdateRecoveredPlayButton);
            return;
        }

        var s = ThemeManager.Strings;
        var originalPlaying = _hub.IsPlaying(PlaybackSessionId.EmbedPayloadOriginal);
        var recoveredPlaying = _hub.IsPlaying(PlaybackSessionId.EmbedPayloadRecovered);
        if (PlayOriginalPayloadButton.Visibility == Visibility.Visible)
        {
            ToolTipService.SetToolTip(
                PlayOriginalPayloadButton,
                originalPlaying ? s.Pause : s.PlayOriginalPayloadAudio);
            PlayOriginalPayloadButton.IsEnabled = _payloadAudio is not null && !_verifying;
        }

        if (PlayRecoveredButton.Visibility == Visibility.Visible)
        {
            ToolTipService.SetToolTip(
                PlayRecoveredButton,
                recoveredPlaying ? s.Pause : s.PlayExtractedAudio);
            PlayRecoveredButton.IsEnabled = _recoveredAudio is not null && !_verifying;
        }
    }

    private void PlayOriginalPayloadButton_Click(object sender, RoutedEventArgs e)
    {
        if (_payloadAudio is null) return;
        try
        {
            _hub.PlayOrToggle(
                PlaybackSessionId.EmbedPayloadOriginal,
                PayloadEnvelope.PrepareAudioForExport(_payloadAudio));
        }
        catch (Exception ex) { StatusText.Text = ex.Message; }
    }

    private void PlayRecoveredButton_Click(object sender, RoutedEventArgs e)
    {
        if (_recoveredAudio is null) return;
        try
        {
            _hub.PlayOrToggle(
                PlaybackSessionId.EmbedPayloadRecovered,
                PayloadEnvelope.PrepareAudioForExport(_recoveredAudio));
        }
        catch (Exception ex) { StatusText.Text = ex.Message; }
    }

    private void CopyOriginalButton_Click(object sender, RoutedEventArgs e)
    {
        var text = MessageTextBox.Text;
        if (string.IsNullOrEmpty(text)) return;
        Clipboard.SetText(text);
        StatusText.Text = ThemeManager.Strings.Copied;
    }

    private void SaveRecoveredButton_Click(object sender, RoutedEventArgs e)
    {
        if (_recoveredImageBytes is not null)
        {
            var isPng = _recoveredImageBytes.Length >= 4 &&
                        _recoveredImageBytes[0] == 0x89 &&
                        _recoveredImageBytes[1] == 0x50;
            var ext = isPng ? "png" : "jpg";
            var dlg = new SaveFileDialog
            {
                Filter = isPng ? "PNG (*.png)|*.png" : "JPEG (*.jpg)|*.jpg",
                FileName = $"verified_payload.{ext}",
            };
            if (dlg.ShowDialog() != true) return;
            File.WriteAllBytes(dlg.FileName, _recoveredImageBytes);
            StatusText.Text = ThemeManager.Strings.SuccessSaved;
            return;
        }

        if (_recoveredAudio is null) return;
        var wavDlg = new SaveFileDialog
        {
            Filter = "WAV (*.wav)|*.wav",
            FileName = "verified_payload.wav",
        };
        if (wavDlg.ShowDialog() != true) return;
        File.WriteAllBytes(
            wavDlg.FileName,
            PayloadEnvelope.PrepareAudioForExport(_recoveredAudio).Encode());
        StatusText.Text = ThemeManager.Strings.SuccessSaved;
    }

    private void CopyRecoveredButton_Click(object sender, RoutedEventArgs e)
    {
        if (string.IsNullOrEmpty(_recoveredText)) return;
        Clipboard.SetText(_recoveredText);
        StatusText.Text = ThemeManager.Strings.Copied;
    }
}
