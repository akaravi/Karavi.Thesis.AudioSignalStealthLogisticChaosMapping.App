using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;
using AudioStegano.Core.Stego;

namespace AudioStegano.Desktop.Controls;

public partial class LogisticMapPreviewControl : UserControl
{
    public const int SampleCount = 120;

    private const double PadL = 44;
    private const double PadR = 8;
    private const double PadT = 8;
    private const double PadB = 26;

    public static readonly DependencyProperty RProperty =
        DependencyProperty.Register(nameof(R), typeof(double), typeof(LogisticMapPreviewControl),
            new PropertyMetadata(3.99, (d, _) => ((LogisticMapPreviewControl)d).Redraw()));

    public static readonly DependencyProperty X0Property =
        DependencyProperty.Register(nameof(X0), typeof(double), typeof(LogisticMapPreviewControl),
            new PropertyMetadata(0.45, (d, _) => ((LogisticMapPreviewControl)d).Redraw()));

    public double R
    {
        get => (double)GetValue(RProperty);
        set => SetValue(RProperty, value);
    }

    public double X0
    {
        get => (double)GetValue(X0Property);
        set => SetValue(X0Property, value);
    }

    public LogisticMapPreviewControl() => InitializeComponent();

    public void SetCaption(string text) => CaptionText.Text = text;

    private static string FormatY(double value)
    {
        var a = Math.Abs(value);
        if (a >= 10) return value.ToString("F1", CultureInfo.InvariantCulture);
        if (a >= 1) return value.ToString("F2", CultureInfo.InvariantCulture);
        return value.ToString("F3", CultureInfo.InvariantCulture);
    }

    private void Redraw()
    {
        if (ChartHost is null) return;
        ChartHost.Child = null;

        var w = ActualWidth > 0 ? ActualWidth : 400;
        var h = ChartHost.Height > 0 ? ChartHost.Height : 168;
        var canvas = new Canvas { Width = w, Height = h };

        Brush lineBrush;
        Brush gridBrush;
        Brush thresholdBrush;
        Brush labelBrush;
        try
        {
            lineBrush = (Brush)FindResource("ChartCoverBrush");
            gridBrush = (Brush)FindResource("BorderBrush");
            thresholdBrush = (Brush)FindResource("ChartStegoBrush");
            labelBrush = (Brush)FindResource("TextBrush");
        }
        catch
        {
            lineBrush = Brushes.Teal;
            gridBrush = Brushes.Gray;
            thresholdBrush = Brushes.MediumPurple;
            labelBrush = Brushes.DimGray;
        }

        var seq = LogisticMap.Sequence(SampleCount, X0, R);
        if (seq.Length < 2) return;

        var yMin = seq.Min();
        var yMax = seq.Max();
        var span = yMax - yMin;
        if (span < 1e-9)
        {
            yMin -= 0.05;
            yMax += 0.05;
        }
        else
        {
            var margin = span * 0.08;
            yMin -= margin;
            yMax += margin;
        }

        var plotW = w - PadL - PadR;
        var plotH = h - PadT - PadB;

        double MapY(double value) =>
            PadT + plotH * (1.0 - (value - yMin) / (yMax - yMin));

        foreach (var level in new[] { 0.0, 0.5, 1.0 })
        {
            var y = MapY(Math.Clamp(level, yMin, yMax));
            canvas.Children.Add(new Line
            {
                X1 = PadL, Y1 = y, X2 = PadL + plotW, Y2 = y,
                Stroke = gridBrush, StrokeThickness = 1, Opacity = 0.55,
            });
        }

        var sum = 0.0;
        foreach (var v in seq) sum += v;
        var threshold = sum / seq.Length;
        canvas.Children.Add(new Line
        {
            X1 = PadL,
            Y1 = MapY(Math.Clamp(threshold, yMin, yMax)),
            X2 = PadL + plotW,
            Y2 = MapY(Math.Clamp(threshold, yMin, yMax)),
            Stroke = thresholdBrush,
            StrokeThickness = 1.25,
            StrokeDashArray = [5, 4],
            Opacity = 0.85,
        });

        var poly = new Polyline
        {
            Stroke = lineBrush,
            StrokeThickness = 2.25,
            StrokeLineJoin = PenLineJoin.Round,
        };
        for (var i = 0; i < seq.Length; i++)
        {
            var x = PadL + i / (double)(seq.Length - 1) * plotW;
            poly.Points.Add(new Point(x, MapY(seq[i])));
        }

        canvas.Children.Add(poly);

        var yMid = (yMin + yMax) / 2;
        foreach (var value in new[] { yMax, yMid, yMin })
        {
            AddAxisLabel(canvas, FormatY(value), PadL - 8, MapY(value), labelBrush,
                horizontalAlignment: HorizontalAlignment.Right, maxWidth: PadL - 10);
        }

        var xTicks = new[] { (1, PadL), (SampleCount / 2, PadL + plotW / 2), (SampleCount, PadL + plotW) };
        foreach (var (step, x) in xTicks)
        {
            AddAxisLabel(canvas, step.ToString(CultureInfo.InvariantCulture), x, PadT + plotH + 4,
                labelBrush, horizontalAlignment: HorizontalAlignment.Center, maxWidth: 48);
        }

        ChartHost.Child = canvas;
    }

    private static void AddAxisLabel(
        Canvas canvas,
        string text,
        double anchorX,
        double anchorY,
        Brush foreground,
        HorizontalAlignment horizontalAlignment,
        double maxWidth)
    {
        var tb = new TextBlock
        {
            Text = text,
            Foreground = foreground,
            FontSize = 10,
            FontFamily = new FontFamily("Segoe UI"),
            Opacity = 0.72,
        };
        tb.Measure(new Size(maxWidth, double.PositiveInfinity));
        tb.Arrange(new Rect(0, 0, tb.DesiredSize.Width, tb.DesiredSize.Height));

        var left = anchorX;
        if (horizontalAlignment == HorizontalAlignment.Right)
            left = anchorX - tb.DesiredSize.Width;
        else if (horizontalAlignment == HorizontalAlignment.Center)
            left = anchorX - tb.DesiredSize.Width / 2;

        Canvas.SetLeft(tb, left);
        Canvas.SetTop(tb, anchorY - tb.DesiredSize.Height / 2);
        canvas.Children.Add(tb);
    }

    protected override void OnRenderSizeChanged(SizeChangedInfo sizeInfo)
    {
        base.OnRenderSizeChanged(sizeInfo);
        Redraw();
    }
}
