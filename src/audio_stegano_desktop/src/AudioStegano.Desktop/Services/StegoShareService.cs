using System.IO;
using System.Windows;
using AudioStegano.Core.Audio;
using AudioStegano.Desktop.Localization;
using Microsoft.Win32;

namespace AudioStegano.Desktop.Services;

/// <summary>Share stego WAV — OS share when possible; otherwise Save dialog (Flutter desktop fallback).</summary>
public static class StegoShareService
{
    public static bool TryShare(WavFile stego, int msgBitLength, Window? owner, AppStrings strings, out string? statusMessage)
    {
        statusMessage = null;
        var bytes = stego.Encode();
        var fileName = StegoFileNaming.Build(msgBitLength);
        var dlg = new SaveFileDialog
        {
            Title = strings.ShareStego,
            Filter = "WAV (*.wav)|*.wav",
            FileName = fileName,
        };
        if (dlg.ShowDialog() != true)
            return false;

        File.WriteAllBytes(dlg.FileName, bytes);
        statusMessage = $"{strings.ShareFileDownloaded} {dlg.FileName}";
        return true;
    }
}
