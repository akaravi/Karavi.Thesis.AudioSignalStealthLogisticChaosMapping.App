using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;

namespace AudioSteg.Desktop.Dialogs;

public partial class RecoveryBitsDialog : Window
{
    private readonly int _bits;
    private readonly int _capacityBits;

    public RecoveryBitsDialog(int msgBitLength, int capacityBits)
    {
        _bits = msgBitLength;
        _capacityBits = capacityBits;
        InitializeComponent();
        ApplyStrings();
        BitsValueText.Text = msgBitLength.ToString();
    }

    private void ApplyStrings()
    {
        var s = ThemeManager.Strings;
        Title = s.EmbedCompleteTitle;
        TitleText.Text = s.EmbedCompleteTitle;
        MessageText.Text = s.EmbedRecoveryMessage;
        ValueLabel.Text = s.MsgBitLength;
        ToolTipService.SetToolTip(CopyButton, s.Copy);
        CapacityHintText.Text = s.EmbedRecoveryCapacityHint(_capacityBits);
        OkButton.Content = s.EmbedRecoveryOk;
    }

    private void CopyButton_Click(object sender, RoutedEventArgs e)
    {
        Clipboard.SetText(_bits.ToString());
        var s = ThemeManager.Strings;
        CopiedHint.Text = s.EmbedRecoveryCopied;
        CopiedHint.Visibility = Visibility.Visible;
        var timer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(2.5) };
        timer.Tick += (_, _) =>
        {
            timer.Stop();
            CopiedHint.Visibility = Visibility.Collapsed;
        };
        timer.Start();
    }

    private void OkButton_Click(object sender, RoutedEventArgs e) => DialogResult = true;
}
