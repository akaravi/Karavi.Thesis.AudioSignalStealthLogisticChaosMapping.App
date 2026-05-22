namespace AudioStegano.Desktop.Models;

public sealed class MetricChipItem(string icon, string label, string value, EmbedMetricKind kind)
{
    public string Icon { get; } = icon;
    public string Label { get; } = label;
    public string Value { get; } = value;
    public EmbedMetricKind Kind { get; } = kind;
}
