using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;
using AudioSteg.Core.Audio;

namespace AudioSteg.Desktop.Controls;

public partial class EqualizerControl : UserControl
{
    public static readonly DependencyProperty BandsProperty =
        DependencyProperty.Register(nameof(Bands), typeof(IReadOnlyList<double>),
            typeof(EqualizerControl),
            new PropertyMetadata(null, (d, _) => ((EqualizerControl)d).Redraw()));

    public static readonly DependencyProperty IsActiveProperty =
        DependencyProperty.Register(nameof(IsActive), typeof(bool),
            typeof(EqualizerControl),
            new PropertyMetadata(false, (d, _) => ((EqualizerControl)d).Redraw()));

    public IReadOnlyList<double>? Bands
    {
        get => (IReadOnlyList<double>?)GetValue(BandsProperty);
        set => SetValue(BandsProperty, value);
    }

    public bool IsActive
    {
        get => (bool)GetValue(IsActiveProperty);
        set => SetValue(IsActiveProperty, value);
    }

    public EqualizerControl() => InitializeComponent();

    public void SetBands(IReadOnlyList<double> bands) => Bands = bands;

    private void Redraw()
    {
        if (Host is null) return;
        Host.Child = null;

        var w = ActualWidth > 0 ? ActualWidth - 16 : 384;
        var h = ActualHeight > 0 ? ActualHeight - 12 : 84;
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

        var bands = NormalizeBands(Bands);
        const double gap = 2;
        var count = bands.Count;
        var barWidth = (w - gap * (count - 1)) / count;

        for (var i = 0; i < count; i++)
        {
            var norm = Math.Clamp(bands[i], 0, 1);
            var barH = norm < 0.02 ? 2 : norm * h;
            var x = i * (barWidth + gap);
            var rect = new Rectangle
            {
                Width = barWidth,
                Height = barH,
                Fill = barBrush,
                RadiusX = 2,
                RadiusY = 2,
            };
            Canvas.SetLeft(rect, x);
            Canvas.SetTop(rect, h - barH);
            canvas.Children.Add(rect);
        }

        Host.Child = canvas;
    }

    private static IReadOnlyList<double> NormalizeBands(IReadOnlyList<double>? bands)
    {
        if (bands is { Count: SpectrumAnalyzer.BandCount }) return bands;
        var outList = new double[SpectrumAnalyzer.BandCount];
        if (bands is null || bands.Count == 0) return outList;
        for (var i = 0; i < SpectrumAnalyzer.BandCount; i++)
        {
            var src = (int)(i * (double)bands.Count / SpectrumAnalyzer.BandCount);
            outList[i] = bands[Math.Clamp(src, 0, bands.Count - 1)];
        }
        return outList;
    }

    protected override void OnRenderSizeChanged(SizeChangedInfo sizeInfo)
    {
        base.OnRenderSizeChanged(sizeInfo);
        Redraw();
    }
}
