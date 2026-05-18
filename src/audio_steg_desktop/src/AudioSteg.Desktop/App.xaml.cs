using System.Windows;

namespace AudioSteg.Desktop;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        AppState.Load();
        ThemeManager.Apply(Resources);
        new MainWindow().Show();
    }
}
