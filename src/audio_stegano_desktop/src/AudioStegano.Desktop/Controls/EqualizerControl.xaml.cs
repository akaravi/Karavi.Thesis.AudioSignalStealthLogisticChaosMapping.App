using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;
using AudioStegano.Core.Audio;

namespace AudioStegano.Desktop.Controls;

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

    public static readonly DependencyProperty RecordingElapsedProperty =
        DependencyProperty.Register(nameof(RecordingElapsed), typeof(TimeSpan?),
            typeof(EqualizerControl),
            new PropertyMetadata(null, (d, _) => ((EqualizerControl)d).Redraw()));

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

    public TimeSpan? RecordingElapsed
    {
        get => (TimeSpan?)GetValue(RecordingElapsedProperty);
        set => SetValue(RecordingElapsedProperty, value);
    }

    public EqualizerControl()
    {
        InitializeComponent();
        Loaded += (_, _) => Redraw();
    }

    public void SetBands(IReadOnlyList<double> bands) => Bands = bands;

    private void Redraw()
    {
        if (Host is null) return;
        Host.Child = null;

        var w = ActualWidth > 0 ? ActualWidth - 20 : 400;
        var h = ActualHeight > 0 ? ActualHeight - 28 : 88;
        var root = new Grid { Width = w };
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        var bandsNorm = NormalizeBands(Bands);
        var peak = bandsNorm.Count > 0 ? bandsNorm.Max() : 0;
        var hasSignal = IsActive && peak > 0.05;
        var levelPct = (int)Math.Clamp(peak * 100, 0, 100);

        var header = new Grid { Margin = new Thickness(0, 0, 0, 6) };
        header.Children.Add(new TextBlock
        {
            Text = "\uE9D9",
            FontFamily = new FontFamily("Segoe MDL2 Assets"),
            FontSize = 14,
            VerticalAlignment = VerticalAlignment.Center,
            Foreground = TryBrush("PrimaryBrush") ?? Brushes.Gray,
        });
        header.Children.Add(new TextBlock
        {
            Text = ThemeManager.Strings.AudioLevel,
            Margin = new Thickness(22, 0, 0, 0),
            VerticalAlignment = VerticalAlignment.Center,
            FontSize = 11,
            FontWeight = FontWeights.SemiBold,
            Foreground = TryBrush("MutedBrush") ?? Brushes.Gray,
        });
        var badges = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            HorizontalAlignment = HorizontalAlignment.Right,
        };
        if (RecordingElapsed is { } elapsed)
        {
            badges.Children.Add(CreateHeaderBadge(
                $"\uE823 {FormatDuration(elapsed)}",
                TryBrush("PrimaryBrush") ?? Brushes.Teal));
        }
        if (IsActive)
        {
            badges.Children.Add(CreateHeaderBadge(
                $"\uE767 {levelPct}%",
                LevelBrush(peak, 1),
                badges.Children.Count > 0 ? new Thickness(8, 0, 0, 0) : default));
        }
        if (badges.Children.Count > 0)
        {
            header.Children.Add(badges);
        }
        Grid.SetRow(header, 0);
        root.Children.Add(header);

        var body = new Grid();
        body.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(14) });
        body.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(8) });
        body.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var meter = new Canvas { Height = h };
        DrawMasterMeter(meter, 14, h, peak, hasSignal);
        Grid.SetColumn(meter, 0);
        body.Children.Add(meter);

        var spectrum = new Canvas { Height = h };
        DrawSpectrum(spectrum, w - 22, h, bandsNorm, hasSignal);
        Grid.SetColumn(spectrum, 2);
        body.Children.Add(spectrum);

        Grid.SetRow(body, 1);
        root.Children.Add(body);

        try
        {
            Host.Background = TryBrush("SurfaceContainerHighBrush")
                ?? new SolidColorBrush(Color.FromArgb(240, 40, 40, 44));
            Host.BorderBrush = IsActive
                ? TryBrush("PrimaryBrush")
                : TryBrush("BorderBrush");
            Host.BorderThickness = IsActive ? new Thickness(1.5) : new Thickness(1);
            Host.Opacity = 1;
        }
        catch { /* theme */ }

        Host.Child = root;
    }

    private void DrawMasterMeter(Canvas canvas, double width, double height, double peak, bool hasSignal)
    {
        var track = new Rectangle
        {
            Width = width,
            Height = height,
            RadiusX = 6,
            RadiusY = 6,
            Fill = TryBrush("BorderBrush") ?? Brushes.DimGray,
            Opacity = 0.35,
        };
        canvas.Children.Add(track);

        var fillH = Math.Max(height * 0.04, height * peak);
        var fill = new Rectangle
        {
            Width = width,
            Height = fillH,
            RadiusX = 6,
            RadiusY = 6,
            Fill = LevelGradient(peak, fillH),
        };
        Canvas.SetTop(fill, height - fillH);
        canvas.Children.Add(fill);

        if (hasSignal && peak > 0.12)
        {
            var lineY = height - height * peak;
            var line = new Line
            {
                X1 = -2,
                Y1 = lineY,
                X2 = width + 2,
                Y2 = lineY,
                Stroke = LevelBrush(peak, 1),
                StrokeThickness = 2,
            };
            canvas.Children.Add(line);
        }
    }

    private void DrawSpectrum(Canvas canvas, double width, double height, IReadOnlyList<double> bands, bool hasSignal)
    {
        const double gap = 3;
        var count = bands.Count;
        var barW = (width - gap * (count - 1)) / count;

        for (var f = 0.25; f <= 0.75; f += 0.25)
        {
            var y = height * (1 - f);
            var grid = new Line
            {
                X1 = 0,
                Y1 = y,
                X2 = width,
                Y2 = y,
                Stroke = TryBrush("BorderBrush") ?? Brushes.Gray,
                Opacity = 0.35,
                StrokeThickness = 1,
            };
            canvas.Children.Add(grid);
        }

        for (var i = 0; i < count; i++)
        {
            var norm = Math.Clamp(bands[i], 0, 1);
            var barH = Math.Max(height * 0.06, norm * height);
            var x = i * (barW + gap);

            var track = new Rectangle
            {
                Width = barW,
                Height = height,
                RadiusX = 4,
                RadiusY = 4,
                Fill = TryBrush("BorderBrush") ?? Brushes.DimGray,
                Opacity = 0.25,
            };
            Canvas.SetLeft(track, x);
            canvas.Children.Add(track);

            var bar = new Rectangle
            {
                Width = barW,
                Height = barH,
                RadiusX = Math.Min(barW / 2, 5),
                RadiusY = Math.Min(barW / 2, 5),
                Fill = hasSignal ? LevelGradient(norm, barH) : (TryBrush("BorderBrush") ?? Brushes.Gray),
                Opacity = hasSignal ? 1 : 0.35,
            };
            Canvas.SetLeft(bar, x);
            Canvas.SetTop(bar, height - barH);
            canvas.Children.Add(bar);
        }
    }

    private static Border CreateHeaderBadge(string text, Brush foreground, Thickness margin = default)
    {
        var color = foreground is SolidColorBrush scb ? scb.Color : Colors.Gray;
        return new Border
        {
            Margin = margin,
            Padding = new Thickness(8, 2, 8, 2),
            CornerRadius = new CornerRadius(8),
            Background = new SolidColorBrush(color) { Opacity = 0.2 },
            BorderBrush = new SolidColorBrush(color) { Opacity = 0.55 },
            BorderThickness = new Thickness(1),
            Child = new TextBlock
            {
                Text = text,
                FontWeight = FontWeights.Bold,
                FontSize = 11,
                Foreground = foreground,
            },
        };
    }

    private static string FormatDuration(TimeSpan d)
    {
        if (d.TotalHours >= 1)
        {
            return $"{(int)d.TotalHours}:{d.Minutes:00}:{d.Seconds:00}";
        }
        return $"{d.Minutes:00}:{d.Seconds:00}";
    }

    private static Brush LevelGradient(double level, double height)
    {
        var top = LevelColor(level);
        var bottom = Color.FromRgb(0, 160, 163);
        var brush = new LinearGradientBrush(bottom, top, new Point(0, 1), new Point(0, 0));
        return brush;
    }

    private static SolidColorBrush LevelBrush(double level, double opacity)
    {
        var c = LevelColor(level);
        return new SolidColorBrush(Color.FromArgb((byte)(opacity * 255), c.R, c.G, c.B));
    }

    private static Color LevelColor(double t)
    {
        if (t < 0.5) return Color.FromRgb(0, 180, 183);
        if (t < 0.82) return Color.FromRgb(255, 183, 77);
        return Color.FromRgb(229, 83, 75);
    }

    private Brush? TryBrush(string key)
    {
        try { return (Brush)FindResource(key); }
        catch { return null; }
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
