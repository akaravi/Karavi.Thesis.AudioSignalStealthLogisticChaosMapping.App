using System.IO;
using System.Windows.Media.Imaging;
using AudioStegano.Core.Stego;

namespace AudioStegano.Desktop.Services;

/// <summary>
/// Compresses a user-picked still image into a JPEG body that fits the ASTG bit budget.
/// Uses WPF imaging (no extra NuGet).
/// </summary>
public static class PayloadImageCodec
{
    public static byte[] CompressToFitBudget(byte[] sourceBytes, int bitBudget)
    {
        var maxBytes = PayloadImageDefaults.MaxImageBytesForBitBudget(bitBudget);
        if (maxBytes < 64)
            throw new InvalidOperationException("Bit budget too small for an image payload");

        BitmapSource bitmap;
        using (var ms = new MemoryStream(sourceBytes))
        {
            var decoder = BitmapDecoder.Create(
                ms,
                BitmapCreateOptions.PreservePixelFormat,
                BitmapCacheOption.OnLoad);
            bitmap = decoder.Frames[0];
        }

        var longEdge = Math.Max(bitmap.PixelWidth, bitmap.PixelHeight);
        if (longEdge > PayloadImageDefaults.MaxLongEdgePx)
        {
            var scale = (double)PayloadImageDefaults.MaxLongEdgePx / longEdge;
            bitmap = new TransformedBitmap(
                bitmap,
                new System.Windows.Media.ScaleTransform(scale, scale));
            bitmap.Freeze();
        }

        for (var edge = PayloadImageDefaults.MaxLongEdgePx;
             edge >= 64;
             edge = Math.Clamp((int)(edge * 0.75), 64, PayloadImageDefaults.MaxLongEdgePx))
        {
            var candidate = bitmap;
            var currentLong = Math.Max(candidate.PixelWidth, candidate.PixelHeight);
            if (currentLong > edge)
            {
                var scale = (double)edge / currentLong;
                candidate = new TransformedBitmap(
                    bitmap,
                    new System.Windows.Media.ScaleTransform(scale, scale));
                candidate.Freeze();
            }

            for (var q = PayloadImageDefaults.JpegQuality;
                 q >= PayloadImageDefaults.MinJpegQuality;
                 q -= 10)
            {
                var jpeg = EncodeJpeg(candidate, q);
                if (jpeg.Length <= maxBytes)
                    return jpeg;
            }
        }

        throw new InvalidOperationException(
            $"Image cannot be compressed under the bit budget ({maxBytes} bytes)");
    }

    static byte[] EncodeJpeg(BitmapSource source, int qualityPercent)
    {
        var encoder = new JpegBitmapEncoder
        {
            QualityLevel = Math.Clamp(qualityPercent, 1, 100),
        };
        encoder.Frames.Add(BitmapFrame.Create(source));
        using var ms = new MemoryStream();
        encoder.Save(ms);
        return ms.ToArray();
    }
}
