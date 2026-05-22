using System.Buffers.Binary;
using System.Text;

namespace AudioStegano.Core.Audio;

/// <summary>Minimal RIFF/WAVE PCM 16-bit reader/writer.</summary>
public sealed class WavFile
{
    public int SampleRate { get; }
    public int NumChannels { get; }
    public int BitsPerSample { get; }
    public short[] Samples { get; }

    public WavFile(int sampleRate, int numChannels, int bitsPerSample, short[] samples)
    {
        SampleRate = sampleRate;
        NumChannels = numChannels;
        BitsPerSample = bitsPerSample;
        Samples = samples;
    }

    public bool IsPcm16Mono => BitsPerSample == 16 && NumChannels == 1;

    public static WavFile Decode(ReadOnlySpan<byte> bytes)
    {
        if (bytes.Length < 44)
            throw new FormatException("WAV too short (<44 bytes)");

        static string Tag(ReadOnlySpan<byte> b, int offset) =>
            Encoding.ASCII.GetString(b.Slice(offset, 4));

        if (Tag(bytes, 0) != "RIFF" || Tag(bytes, 8) != "WAVE")
            throw new FormatException("Not a RIFF/WAVE file");

        var pos = 12;
        int? sampleRate = null, numChannels = null, bitsPerSample = null, formatTag = null;
        short[]? samples = null;

        while (pos + 8 <= bytes.Length)
        {
            var chunkId = Tag(bytes, pos);
            var chunkSize = BinaryPrimitives.ReadInt32LittleEndian(bytes.Slice(pos + 4, 4));
            var dataStart = pos + 8;

            if (chunkId == "fmt ")
            {
                formatTag = BinaryPrimitives.ReadInt16LittleEndian(bytes.Slice(dataStart, 2));
                numChannels = BinaryPrimitives.ReadInt16LittleEndian(bytes.Slice(dataStart + 2, 2));
                sampleRate = BinaryPrimitives.ReadInt32LittleEndian(bytes.Slice(dataStart + 4, 4));
                bitsPerSample = BinaryPrimitives.ReadInt16LittleEndian(bytes.Slice(dataStart + 14, 2));
            }
            else if (chunkId == "data")
            {
                if (bitsPerSample is null || formatTag is null)
                    throw new FormatException("data chunk before fmt chunk");
                if (formatTag != 1)
                    throw new FormatException($"Only PCM (1) supported, got {formatTag}");
                if (bitsPerSample != 16)
                    throw new FormatException($"Only 16-bit PCM supported, got {bitsPerSample}-bit");

                var sampleCount = chunkSize / 2;
                samples = new short[sampleCount];
                for (var i = 0; i < sampleCount; i++)
                    samples[i] = BinaryPrimitives.ReadInt16LittleEndian(bytes.Slice(dataStart + i * 2, 2));
            }

            pos = dataStart + chunkSize + (chunkSize % 2);
        }

        if (sampleRate is null || numChannels is null || bitsPerSample is null || samples is null)
            throw new FormatException("Missing fmt or data chunk");

        return new WavFile(sampleRate.Value, numChannels.Value, bitsPerSample.Value, samples);
    }

    public static WavFile Decode(byte[] bytes) => Decode(bytes.AsSpan());

    public byte[] Encode()
    {
        var dataSize = Samples.Length * (BitsPerSample / 8);
        const int fmtChunkSize = 16;
        var riffSize = 4 + (8 + fmtChunkSize) + (8 + dataSize);
        var outBytes = new byte[8 + riffSize];

        void WriteTag(int offset, string tag)
        {
            Encoding.ASCII.GetBytes(tag, outBytes.AsSpan(offset, 4));
        }

        WriteTag(0, "RIFF");
        BinaryPrimitives.WriteInt32LittleEndian(outBytes.AsSpan(4, 4), riffSize);
        WriteTag(8, "WAVE");
        WriteTag(12, "fmt ");
        BinaryPrimitives.WriteInt32LittleEndian(outBytes.AsSpan(16, 4), fmtChunkSize);
        BinaryPrimitives.WriteInt16LittleEndian(outBytes.AsSpan(20, 2), 1);
        BinaryPrimitives.WriteInt16LittleEndian(outBytes.AsSpan(22, 2), (short)NumChannels);
        BinaryPrimitives.WriteInt32LittleEndian(outBytes.AsSpan(24, 4), SampleRate);
        var byteRate = SampleRate * NumChannels * (BitsPerSample / 8);
        BinaryPrimitives.WriteInt32LittleEndian(outBytes.AsSpan(28, 4), byteRate);
        var blockAlign = NumChannels * (BitsPerSample / 8);
        BinaryPrimitives.WriteInt16LittleEndian(outBytes.AsSpan(32, 2), (short)blockAlign);
        BinaryPrimitives.WriteInt16LittleEndian(outBytes.AsSpan(34, 2), (short)BitsPerSample);
        WriteTag(36, "data");
        BinaryPrimitives.WriteInt32LittleEndian(outBytes.AsSpan(40, 4), dataSize);
        for (var i = 0; i < Samples.Length; i++)
            BinaryPrimitives.WriteInt16LittleEndian(outBytes.AsSpan(44 + i * 2, 2), Samples[i]);

        return outBytes;
    }

    public WavFile ToMono()
    {
        if (NumChannels == 1) return this;
        var mono = new short[Samples.Length / NumChannels];
        for (var i = 0; i < mono.Length; i++)
        {
            var sum = 0;
            for (var c = 0; c < NumChannels; c++)
                sum += Samples[i * NumChannels + c];
            mono[i] = (short)Math.Clamp(sum / NumChannels, -32768, 32767);
        }
        return new WavFile(SampleRate, 1, BitsPerSample, mono);
    }
}
