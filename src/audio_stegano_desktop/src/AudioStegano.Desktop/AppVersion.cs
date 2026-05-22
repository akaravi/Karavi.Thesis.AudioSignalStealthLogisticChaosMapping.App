using System.Reflection;

namespace AudioStegano.Desktop;

/// <summary>Matches Flutter <c>pubspec.yaml</c> version (e.g. 1.0.0+1).</summary>
public static class AppVersion
{
    public static string Display =>
        Assembly.GetExecutingAssembly()
            .GetCustomAttribute<AssemblyInformationalVersionAttribute>()
            ?.InformationalVersion
        ?? Assembly.GetExecutingAssembly().GetName().Version?.ToString(3)
        ?? "1.0.0";
}
