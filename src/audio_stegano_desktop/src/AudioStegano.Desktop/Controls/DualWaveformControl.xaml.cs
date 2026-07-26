using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;
using AudioStegano.Core.Audio;

namespace AudioStegano.Desktop.Controls;

public partial class DualWaveformControl : UserControl
{
    public static readonly DependencyProperty CoverEnvelopeProperty =
        DependencyProperty.Register(nameof(CoverEnvelope), typeof(IReadOnlyList<double>),
            typeof(DualWaveformControl),
            new PropertyMetadata(null, (d, _) => ((DualWaveformControl)d).Redraw()));

    public static readonly DependencyProperty StegoEnvelopeProperty =
        DependencyProperty.Register(nameof(StegoEnvelope), typeof(IReadOnlyList<double>),
            typeof(DualWaveformControl),
            new PropertyMetadata(null, (d, _) => ((DualWaveformControl)d).Redraw()));

    public IReadOnlyList<double>? CoverEnvelope
    {
        get => (IReadOnlyList<double>?)GetValue(CoverEnvelopeProperty);
        set => SetValue(CoverEnvelopeProperty, value);
    }

    public IReadOnlyList<double>? StegoEnvelope
    {
        get => (IReadOnlyList<double>?)GetValue(StegoEnvelopeProperty);
        set => SetValue(StegoEnvelopeProperty, value);
    }

    public DualWaveformControl() => InitializeComponent();

    public void SetLegends(string coverLabel, string stegoLabel)
    {
        CoverLegend.Text = coverLabel;
        StegoLegend.Text = stegoLabel;
    }

    private void Redraw()
    {
        if (ChartHost is null) return;
        ChartHost.Child = null;

        var w = ActualWidth > 0 ? ActualWidth : 400;
        var h = ChartHost.Height > 0 ? ChartHost.Height : 148;
        var canvas = new Canvas { Width = w, Height = h };

        Brush coverBrush;
        Brush stegoBrush;
        Brush gridBrush;
        try
        {
            coverBrush = (Brush)FindResource("ChartCoverBrush");
            stegoBrush = (Brush)FindResource("ChartStegoBrush");
            gridBrush = (Brush)FindResource("BorderBrush");
        }
        catch
        {
            coverBrush = Brushes.MediumPurple;
            stegoBrush = Brushes.Teal;
            gridBrush = Brushes.Gray;
        }

        var midY = h / 2;
        canvas.Children.Add(new Line
        {
            X1 = 0, Y1 = midY, X2 = w, Y2 = midY,
            Stroke = gridBrush, StrokeThickness = 1, Opacity = 0.55,
        });

        var normalized = WaveformDisplay.NormalizeForDisplay([CoverEnvelope, StegoEnvelope]);
        var cover = normalized.Length > 0 ? normalized[0] : Array.Empty<double>();
        var stego = normalized.Length > 1 ? normalized[1] : Array.Empty<double>();

        if (cover.Count > 0)
            DrawSeries(canvas, cover, coverBrush, w, midY, dashed: false);
        if (stego.Count > 0)
            DrawSeries(canvas, stego, stegoBrush, w, midY, dashed: true);

        ChartHost.Child = canvas;
    }

    private static void DrawSeries(
        Canvas canvas,
        IReadOnlyList<double> samples,
        Brush brush,
        double width,
        double midY,
        bool dashed)
    {
        if (samples.Count < 2) return;

        var fill = new Polygon
        {
            Fill = brush,
            Opacity = dashed ? 0.12 : 0.22,
            StrokeThickness = 0,
        };
        var top = new Polyline
        {
            Stroke = brush,
            StrokeThickness = dashed ? 2.25 : 2.75,
            StrokeLineJoin = PenLineJoin.Round,
        };
        var bottom = new Polyline
        {
            Stroke = brush,
            StrokeThickness = dashed ? 2.25 : 2.75,
            StrokeLineJoin = PenLineJoin.Round,
        };
        if (dashed)
        {
            top.StrokeDashArray = [4, 3];
            bottom.StrokeDashArray = [4, 3];
        }

        var n = samples.Count;
        for (var i = 0; i < n; i++)
        {
            var x = i / (double)(n - 1) * width;
            var amp = Math.Clamp(samples[i], 0, 1) * (midY - 3);
            top.Points.Add(new Point(x, midY - amp));
            bottom.Points.Add(new Point(x, midY + amp));
            fill.Points.Add(new Point(x, midY - amp));
        }
        for (var i = n - 1; i >= 0; i--)
        {
            var x = i / (double)(n - 1) * width;
            var amp = Math.Clamp(samples[i], 0, 1) * (midY - 3);
            fill.Points.Add(new Point(x, midY + amp));
        }

        canvas.Children.Add(fill);
        canvas.Children.Add(top);
        canvas.Children.Add(bottom);
    }

    protected override void OnRenderSizeChanged(SizeChangedInfo sizeInfo)
    {
        base.OnRenderSizeChanged(sizeInfo);
        Redraw();
    }
}
