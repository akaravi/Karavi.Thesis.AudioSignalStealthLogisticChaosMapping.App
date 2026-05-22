using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Shapes;

namespace AudioStegano.Desktop.Controls;

public partial class RecordButtonControl : UserControl
{
    public static readonly DependencyProperty IsRecordingProperty =
        DependencyProperty.Register(nameof(IsRecording), typeof(bool), typeof(RecordButtonControl),
            new PropertyMetadata(false, (d, e) => ((RecordButtonControl)d).OnRecordingChanged((bool)e.NewValue!)));

    public event EventHandler? Click;

    public bool IsRecording
    {
        get => (bool)GetValue(IsRecordingProperty);
        set => SetValue(IsRecordingProperty, value);
    }

    public string LabelIdle { get; set; } = "Start";
    public string LabelActive { get; set; } = "Stop";

    public RecordButtonControl()
    {
        InitializeComponent();
        Loaded += (_, _) => RefreshVisual();
    }

    private void OnRecordingChanged(bool recording)
    {
        RefreshVisual();
        if (recording)
            StartPulse();
        else
            StopPulse();
    }

    public void RefreshVisual()
    {
        LabelText.Text = IsRecording ? LabelActive : LabelIdle;
        try
        {
            MainButton.Background = IsRecording
                ? (Brush)FindResource("ErrorBrush")
                : (Brush)FindResource("AccentBrush");
        }
        catch { /* theme not ready */ }

        IconGlyph.Text = IsRecording ? "\uE71A" : "\uE720";
    }

    private void StartPulse()
    {
        PulseRing.Opacity = 0.2;
        var anim = new DoubleAnimation(50, 65, TimeSpan.FromMilliseconds(550))
        {
            AutoReverse = true,
            RepeatBehavior = RepeatBehavior.Forever,
        };
        PulseRing.BeginAnimation(WidthProperty, anim);
        PulseRing.BeginAnimation(HeightProperty, anim);
    }

    private void StopPulse()
    {
        PulseRing.BeginAnimation(WidthProperty, null);
        PulseRing.BeginAnimation(HeightProperty, null);
        PulseRing.Width = 55;
        PulseRing.Height = 55;
        PulseRing.Opacity = 0;
    }

    private void MainButton_Click(object sender, RoutedEventArgs e) => Click?.Invoke(this, e);
}
