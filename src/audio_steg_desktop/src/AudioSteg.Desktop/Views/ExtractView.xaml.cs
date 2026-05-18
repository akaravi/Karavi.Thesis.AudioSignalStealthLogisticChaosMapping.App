using System.IO;
using System.Windows;
using System.Windows.Controls;
using Microsoft.Win32;

namespace AudioSteg.Desktop.Views;

public partial class ExtractView : UserControl
{
    public ExtractView()
    {
        InitializeComponent();
        Loaded += (_, _) => ApplyStrings();
    }

    public void ApplyStrings()
    {
        var s = ThemeManager.Strings;
        PickTitle.Text = s.PickFile;
        BitLengthBox.SetValue(ToolTipService.ToolTipProperty, s.MsgBitLengthHint);
        BitLengthHelper.Text = s.MsgBitLengthHelper;
        PickButton.Content = s.PickFile;
        ResultTitle.Text = s.ExtractedText;
        CopyButton.Content = s.Copy;
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

    private async void PickButton_Click(object sender, RoutedEventArgs e)
    {
        var bitLen = ParseBitLength();
        if (bitLen is null) return;

        var s = ThemeManager.Strings;
        var dlg = new OpenFileDialog { Filter = "WAV files (*.wav)|*.wav" };
        if (dlg.ShowDialog() != true) return;

        BusyBar.Visibility = Visibility.Visible;
        StatusText.Text = s.Processing;
        PickButton.IsEnabled = false;
        ResultPanel.Visibility = Visibility.Collapsed;

        string? text = null;
        string? error = null;
        await Task.Run(() =>
        {
            try
            {
                var bytes = File.ReadAllBytes(dlg.FileName);
                var wav = Core.Audio.WavFile.Decode(bytes);
                text = AppState.Watermarking.Extract(wav, bitLen.Value);
            }
            catch (Exception ex)
            {
                error = ex.Message;
            }
        });

        BusyBar.Visibility = Visibility.Collapsed;
        PickButton.IsEnabled = true;

        if (error is not null)
        {
            StatusText.Text = error;
            return;
        }

        if (text is null)
        {
            StatusText.Text = s.KeyMismatch;
            ResultText.Text = s.NoText;
            ResultPanel.Visibility = Visibility.Visible;
            return;
        }

        StatusText.Text = string.Empty;
        ResultText.Text = text;
        ResultPanel.Visibility = Visibility.Visible;
    }

    private void CopyButton_Click(object sender, RoutedEventArgs e)
    {
        if (!string.IsNullOrEmpty(ResultText.Text))
            Clipboard.SetText(ResultText.Text);
        StatusText.Text = ThemeManager.Strings.Copied;
    }
}
