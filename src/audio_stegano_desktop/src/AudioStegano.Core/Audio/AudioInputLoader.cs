using NAudio.MediaFoundation;
using NAudio.Wave;
using NAudio.Wave.SampleProviders;

namespace AudioStegano.Core.Audio;

/// <summary>Loads WAV, MP3, or MP4 (Windows) into <see cref="WavFile"/> (mono PCM 16-bit) for steganography.</summary>
public static class AudioInputLoader
{
    public const string OpenDialogFilter =
        "Audio (*.wav;*.mp3;*.mp4)|*.wav;*.mp3;*.mp4|WAV (*.wav)|*.wav|MP3 (*.mp3)|*.mp3|MP4 (*.mp4)|*.mp4";

    public static WavFile LoadFromPath(string filePath)
    {
        var ext = Path.GetExtension(filePath).ToLowerInvariant();
        return ext switch
        {
            ".wav" => WavFile.Decode(File.ReadAllBytes(filePath)),
            ".mp3" => DecodeMp3(File.OpenRead(filePath)),
            ".mp4" => DecodeMp4FromPath(filePath),
            _ => throw new NotSupportedException($"Unsupported audio format: {ext}"),
        };
    }

    public static WavFile LoadFromBytes(byte[] bytes, string fileName)
    {
        var ext = Path.GetExtension(fileName).ToLowerInvariant();
        return ext switch
        {
            ".wav" => WavFile.Decode(bytes),
            ".mp3" => DecodeMp3(new MemoryStream(bytes)),
            ".mp4" => DecodeMp4FromBytes(bytes),
            _ => throw new NotSupportedException($"Unsupported audio format: {ext}"),
        };
    }

    private static WavFile DecodeMp4FromPath(string filePath)
    {
        if (!OperatingSystem.IsWindows())
            throw new NotSupportedException("MP4 decode is supported on Windows only.");

        try
        {
            EnsureMediaFoundationStarted();
            using var reader = new MediaFoundationReader(filePath);
            return FromSampleProvider(reader.ToSampleProvider(), reader.WaveFormat.SampleRate);
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"MP4 decode failed: {ex.Message}", ex);
        }
    }

    private static WavFile DecodeMp4FromBytes(byte[] bytes)
    {
        if (!OperatingSystem.IsWindows())
            throw new NotSupportedException("MP4 decode is supported on Windows only.");

        var temp = Path.Combine(Path.GetTempPath(), $"audiostegano_{Guid.NewGuid():N}.mp4");
        try
        {
            File.WriteAllBytes(temp, bytes);
            return DecodeMp4FromPath(temp);
        }
        finally
        {
            try { File.Delete(temp); }
            catch { /* ignore */ }
        }
    }

    private static int _mediaFoundationStarted;

    private static void EnsureMediaFoundationStarted()
    {
        if (Interlocked.Exchange(ref _mediaFoundationStarted, 1) == 0)
            MediaFoundationApi.Startup();
    }

    public static void ShutdownMediaFoundation()
    {
        if (Interlocked.Exchange(ref _mediaFoundationStarted, 0) == 1)
            MediaFoundationApi.Shutdown();
    }

    private static WavFile DecodeMp3(Stream stream)
    {
        try
        {
            using var reader = new Mp3FileReader(stream);
            return FromSampleProvider(reader.ToSampleProvider(), reader.WaveFormat.SampleRate);
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"MP3 decode failed: {ex.Message}", ex);
        }
    }

    private static WavFile FromSampleProvider(ISampleProvider source, int sampleRate)
    {
        ISampleProvider mono = source.WaveFormat.Channels > 1
            ? new StereoToMonoSampleProvider(source)
            : source;

        var floats = new List<float>();
        var buffer = new float[sampleRate * 2];
        int read;
        while ((read = mono.Read(buffer, 0, buffer.Length)) > 0)
        {
            for (var i = 0; i < read; i++)
                floats.Add(buffer[i]);
        }

        var samples = new short[floats.Count];
        for (var i = 0; i < floats.Count; i++)
        {
            var v = (int)(floats[i] * 32767f);
            samples[i] = (short)Math.Clamp(v, -32768, 32767);
        }

        return new WavFile(sampleRate, 1, 16, samples);
    }
}
