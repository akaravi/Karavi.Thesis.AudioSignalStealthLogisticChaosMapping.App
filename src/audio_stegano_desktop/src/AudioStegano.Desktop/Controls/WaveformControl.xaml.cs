using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;

namespace AudioStegano.Desktop.Controls;

public partial class WaveformControl : UserControl
{
    public static readonly DependencyProperty SamplesProperty =
        DependencyProperty.Register(nameof(Samples), typeof(IReadOnlyList<double>), typeof(WaveformControl),
            new PropertyMetadata(null, (d, _) => ((WaveformControl)d).Redraw()));

    public static readonly DependencyProperty IsActiveProperty =
        DependencyProperty.Register(nameof(IsActive), typeof(bool), typeof(WaveformControl),
            new PropertyMetadata(false, (d, _) => ((WaveformControl)d).Redraw()));

    public IReadOnlyList<double>? Samples
    {
        get => (IReadOnlyList<double>?)GetValue(SamplesProperty);
        set => SetValue(SamplesProperty, value);
    }

    public bool IsActive
    {
        get => (bool)GetValue(IsActiveProperty);
        set => SetValue(IsActiveProperty, value);
    }

    public WaveformControl() => InitializeComponent();

    public void SetSamples(IEnumerable<double> samples)
    {
        Samples = samples.ToList();
        Redraw();
    }

    private void Redraw()
    {
        if (Host is null) return;
        Host.Child = null;
        var w = ActualWidth > 0 ? ActualWidth : 400;
        var h = ActualHeight > 0 ? ActualHeight : 80;
        var canvas = new Canvas { Width = w, Height = h };

        Brush barBrush;
        try
        {
            barBrush = IsActive
                ? (Brush)FindResource("AccentBrush")
                : (Brush)FindResource("BorderBrush");
        }
        catch
        {
            barBrush = Brushes.Gray;
        }

        var samples = Samples;
        if (samples is null || samples.Count == 0)
        {
            var line = new Line
            {
                X1 = 0, Y1 = h / 2, X2 = w, Y2 = h / 2,
                Stroke = barBrush, StrokeThickness = 2, Opacity = 0.4,
            };
            canvas.Children.Add(line);
            Host.Child = canvas;
            return;
        }

        const double barWidth = 4;
        const double gap = 3;
        var maxBars = (int)(w / (barWidth + gap));
        var visible = samples.Count > maxBars
            ? samples.Skip(samples.Count - maxBars).ToList()
            : samples.ToList();

        for (var i = 0; i < visible.Count; i++)
        {
            var db = Math.Clamp(visible[i], -60.0, 0.0);
            var norm = (db + 60.0) / 60.0;
            var barH = Math.Max(2.0, norm * h);
            var x = i * (barWidth + gap) + barWidth / 2;
            var y1 = (h - barH) / 2;
            var rect = new Rectangle
            {
                Width = barWidth,
                Height = barH,
                Fill = barBrush,
                RadiusX = 2,
                RadiusY = 2,
            };
            Canvas.SetLeft(rect, x - barWidth / 2);
            Canvas.SetTop(rect, y1);
            canvas.Children.Add(rect);
        }

        Host.Child = canvas;
    }

    protected override void OnRenderSizeChanged(SizeChangedInfo sizeInfo)
    {
        base.OnRenderSizeChanged(sizeInfo);
        Redraw();
    }
}
