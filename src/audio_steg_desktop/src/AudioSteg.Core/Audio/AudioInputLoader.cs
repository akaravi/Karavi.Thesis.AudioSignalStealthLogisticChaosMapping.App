using NAudio.Wave;
using NAudio.Wave.SampleProviders;

namespace AudioSteg.Core.Audio;

/// <summary>Loads WAV or MP3 into <see cref="WavFile"/> (mono PCM 16-bit) for steganography.</summary>
public static class AudioInputLoader
{
    public const string OpenDialogFilter =
        "Audio (*.wav;*.mp3)|*.wav;*.mp3|WAV (*.wav)|*.wav|MP3 (*.mp3)|*.mp3";

    public static WavFile LoadFromPath(string filePath)
    {
        var ext = Path.GetExtension(filePath).ToLowerInvariant();
        return ext switch
        {
            ".wav" => WavFile.Decode(File.ReadAllBytes(filePath)),
            ".mp3" => DecodeMp3(File.OpenRead(filePath)),
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
            _ => throw new NotSupportedException($"Unsupported audio format: {ext}"),
        };
    }

    private static WavFile DecodeMp3(Stream stream)
    {
        using var reader = new Mp3FileReader(stream);
        return FromSampleProvider(reader.ToSampleProvider(), reader.WaveFormat.SampleRate);
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
