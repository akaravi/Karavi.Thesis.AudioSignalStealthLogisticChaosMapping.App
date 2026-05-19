using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace AudioSteg.Desktop.Controls;

public partial class LoadFileButtonControl : UserControl
{
    public event EventHandler? Click;

    public string Label { get; set; } = "Upload file";

    public LoadFileButtonControl()
    {
        InitializeComponent();
        Loaded += (_, _) => RefreshVisual();
    }

    public void RefreshVisual()
    {
        LabelText.Text = Label;
        try
        {
            MainButton.Background = (Brush)FindResource("PrimaryBrush");
        }
        catch
        {
            /* theme not ready */
        }
    }

    private void MainButton_Click(object sender, RoutedEventArgs e) => Click?.Invoke(this, e);
}
