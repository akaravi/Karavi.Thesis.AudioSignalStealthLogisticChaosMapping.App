using System.Text;
using AudioStegano.Core.Audio;

namespace AudioStegano.Core.Stego;

/// <summary>Content type byte in the ASTG header.</summary>
public enum StegoPayloadType : byte
{
    Text = 0x01,
    Image = 0x02,
    Audio = 0x03,
    Other = 0x04,
}

/// <summary>Default payload voice recording parameters (lowest acceptable quality).</summary>
public static class PayloadAudioDefaults
{
    public const int SampleRate = 8000;
    public const int Channels = 1;
    public const int BitsPerSample = 8;
    public const int EnvelopeOverheadBytes = 12;
    /// <summary>sampleRate u16 · ch u8 · bits u8 · numSamples u32 · peakAbs u16.</summary>
    public const int AudioMetaBytes = 10;
    public const int ExportSampleRate = 16000;

    public static int MaxPcmBytesForBitBudget(int bitBudget)
    {
        var maxBytes = bitBudget / 8;
        var usable = maxBytes - EnvelopeOverheadBytes - AudioMetaBytes;
        return usable < 0 ? 0 : usable;
    }

    public static int MaxPcmSamplesForBitBudget(int bitBudget) =>
        MaxPcmBytesForBitBudget(bitBudget);

    public static TimeSpan MaxDurationForBitBudget(int bitBudget)
    {
        var samples = MaxPcmSamplesForBitBudget(bitBudget);
        return TimeSpan.FromMilliseconds(samples * 1000.0 / SampleRate);
    }
}

/// <summary>Still-image payload defaults (JPEG body under ASTG type Image).</summary>
public static class PayloadImageDefaults
{
    public const int EnvelopeOverheadBytes = 12;
    public const int MaxLongEdgePx = 240;
    public const int JpegQuality = 55;
    public const int MinJpegQuality = 25;

    public static int MaxImageBytesForBitBudget(int bitBudget)
    {
        var maxBytes = bitBudget / 8;
        var usable = maxBytes - EnvelopeOverheadBytes;
        return usable < 0 ? 0 : usable;
    }
}

/// <summary>Result of peeling recovered stego bits (envelope or legacy text).</summary>
public sealed class StegoPayloadResult
{
    public StegoPayloadType? Type { get; }
    public bool IsLegacy { get; }
    public string? Text { get; }
    public WavFile? Audio { get; }
    /// <summary>JPEG/PNG file bytes when <see cref="Type"/> is <see cref="StegoPayloadType.Image"/>.</summary>
    public byte[]? ImageBytes { get; }
    public byte[]? RawBody { get; }

    private StegoPayloadResult(
        StegoPayloadType? type,
        bool isLegacy,
        string? text = null,
        WavFile? audio = null,
        byte[]? imageBytes = null,
        byte[]? rawBody = null)
    {
        Type = type;
        IsLegacy = isLegacy;
        Text = text;
        Audio = audio;
        ImageBytes = imageBytes;
        RawBody = rawBody;
    }

    public static StegoPayloadResult LegacyText(string? text) =>
        new(StegoPayloadType.Text, true, text: text);

    public static StegoPayloadResult FromText(string text) =>
        new(StegoPayloadType.Text, false, text: text);

    public static StegoPayloadResult FromAudio(WavFile wav) =>
        new(StegoPayloadType.Audio, false, audio: wav);

    public static StegoPayloadResult FromImage(byte[] fileBytes) =>
        new(StegoPayloadType.Image, false, imageBytes: fileBytes);

    public static StegoPayloadResult Unsupported(StegoPayloadType type, byte[] body) =>
        new(type, false, rawBody: body);
}

/// <summary>
/// ASTG payload envelope — content-type header before stego body bits.
/// Layout: [Magic 4B "ASTG"][Ver 1B][Type 1B][Flags 2B BE][BodyLen u32 BE][Body…]
/// </summary>
public static class PayloadEnvelope
{
    public static readonly byte[] MagicBytes = [0x41, 0x53, 0x54, 0x47];
    public const byte Version = 1;
    public const int HeaderByteLength = 12;
    public const int AudioMetaByteLength = 10;
    public const int AudioMetaByteLengthLegacy = 8;

    public static bool HasMagic(ReadOnlySpan<byte> bytes)
    {
        if (bytes.Length < 4) return false;
        for (var i = 0; i < 4; i++)
        {
            if (bytes[i] != MagicBytes[i]) return false;
        }
        return true;
    }

    public static bool HasMagicBits(byte[] bits)
    {
        if (bits.Length < 32) return false;
        var headerBits = new byte[32];
        Array.Copy(bits, headerBits, 32);
        return HasMagic(BitsToBytes(headerBits));
    }

    public static byte[] BytesToBits(byte[] bytes)
    {
        var outBits = new byte[bytes.Length * 8];
        var pos = 0;
        foreach (var b in bytes)
        {
            for (var bit = 7; bit >= 0; bit--)
                outBits[pos++] = (byte)((b >> bit) & 1);
        }
        return outBits;
    }

    public static byte[] BitsToBytes(byte[] bits)
    {
        if (bits.Length % 8 != 0)
            throw new ArgumentException("bits length must be a multiple of 8");
        var bytes = new byte[bits.Length / 8];
        var pos = 0;
        for (var i = 0; i < bytes.Length; i++)
        {
            var b = 0;
            for (var bit = 0; bit < 8; bit++)
                b = (b << 1) | (bits[pos++] & 1);
            bytes[i] = (byte)b;
        }
        return bytes;
    }

    public static byte[] PackBytes(StegoPayloadType type, byte[] body, ushort flags = 0)
    {
        var outBytes = new byte[HeaderByteLength + body.Length];
        MagicBytes.CopyTo(outBytes, 0);
        outBytes[4] = Version;
        outBytes[5] = (byte)type;
        WriteUInt16Be(outBytes, 6, flags);
        WriteUInt32Be(outBytes, 8, (uint)body.Length);
        Buffer.BlockCopy(body, 0, outBytes, HeaderByteLength, body.Length);
        return outBytes;
    }

    public static byte[] PackBits(
        StegoPayloadType type,
        byte[] body,
        ushort flags = 0,
        int? fixedBitLength = null)
    {
        var packed = BytesToBits(PackBytes(type, body, flags));
        if (fixedBitLength is null or <= 0) return packed;
        if (packed.Length > fixedBitLength.Value)
            throw new ArgumentException(
                $"Envelope needs {packed.Length} bits; fixed limit is {fixedBitLength}.");
        if (packed.Length == fixedBitLength.Value) return packed;
        var padded = new byte[fixedBitLength.Value];
        Array.Copy(packed, padded, packed.Length);
        return padded;
    }

    public static byte[] PackTextBits(string text, int? fixedBitLength = null)
    {
        var body = Encoding.UTF8.GetBytes(text);
        return PackBits(StegoPayloadType.Text, body, fixedBitLength: fixedBitLength);
    }

    public static byte[] PackAudioBits(WavFile audio, int? fixedBitLength = null)
    {
        var body = EncodeAudioBody(audio);
        return PackBits(StegoPayloadType.Audio, body, fixedBitLength: fixedBitLength);
    }

    /// <summary>Packs a still image file body (JPEG/PNG bytes) as ASTG Image.</summary>
    public static byte[] PackImageBits(byte[] imageFileBytes, int? fixedBitLength = null)
    {
        if (imageFileBytes is null || imageFileBytes.Length == 0)
            throw new ArgumentException("Image payload is empty");
        if (!LooksLikeImageFile(imageFileBytes))
            throw new ArgumentException("Image payload must be JPEG or PNG");
        return PackBits(StegoPayloadType.Image, imageFileBytes, fixedBitLength: fixedBitLength);
    }

    public static bool LooksLikeImageFile(ReadOnlySpan<byte> bytes)
    {
        if (bytes.Length < 4) return false;
        if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true; // JPEG
        if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47)
            return true; // PNG
        return false;
    }

    public static StegoPayloadResult UnpackBits(byte[] bits)
    {
        if (bits.Length == 0)
            return StegoPayloadResult.LegacyText(string.Empty);
        if (bits.Length % 8 != 0)
            return StegoPayloadResult.LegacyText(null);
        if (!HasMagicBits(bits))
            return StegoPayloadResult.LegacyText(MessageBits.ToUtf8Text(bits));

        var allBytes = BitsToBytes(bits);
        if (allBytes.Length < HeaderByteLength)
            return StegoPayloadResult.LegacyText(null);
        if (allBytes[4] != Version)
            return StegoPayloadResult.LegacyText(null);
        if (!Enum.IsDefined(typeof(StegoPayloadType), allBytes[5]))
            return StegoPayloadResult.LegacyText(null);
        var type = (StegoPayloadType)allBytes[5];
        var bodyLen = (int)ReadUInt32Be(allBytes, 8);
        if (HeaderByteLength + bodyLen > allBytes.Length)
            return StegoPayloadResult.LegacyText(null);
        var body = new byte[bodyLen];
        Buffer.BlockCopy(allBytes, HeaderByteLength, body, 0, bodyLen);

        return type switch
        {
            StegoPayloadType.Text => TryDecodeText(body),
            StegoPayloadType.Audio => TryDecodeAudio(body),
            StegoPayloadType.Image => LooksLikeImageFile(body)
                ? StegoPayloadResult.FromImage(body)
                : StegoPayloadResult.Unsupported(type, body),
            _ => StegoPayloadResult.Unsupported(type, body),
        };
    }

    public static byte[] EncodeAudioBody(WavFile wav)
    {
        var mono = wav.ToMono();
        short[] pcm16;
        if (mono.SampleRate == PayloadAudioDefaults.SampleRate)
            pcm16 = mono.Samples;
        else
            pcm16 = ResampleMono16(mono.Samples, mono.SampleRate, PayloadAudioDefaults.SampleRate);

        var (u8, peakAbs) = Pcm16ToUnsigned8PeakNormalized(pcm16);
        var outBytes = new byte[AudioMetaByteLength + u8.Length];
        WriteUInt16Be(outBytes, 0, (ushort)PayloadAudioDefaults.SampleRate);
        outBytes[2] = (byte)PayloadAudioDefaults.Channels;
        outBytes[3] = (byte)PayloadAudioDefaults.BitsPerSample;
        WriteUInt32Be(outBytes, 4, (uint)u8.Length);
        WriteUInt16Be(outBytes, 8, (ushort)peakAbs);
        Buffer.BlockCopy(u8, 0, outBytes, AudioMetaByteLength, u8.Length);
        return outBytes;
    }

    public static WavFile DecodeAudioBody(byte[] body)
    {
        if (body.Length < AudioMetaByteLengthLegacy)
            throw new FormatException("Audio body too short");
        var sampleRate = ReadUInt16Be(body, 0);
        var channels = body[2];
        var bitsPerSample = body[3];
        var numSamples = (int)ReadUInt32Be(body, 4);
        if (channels != 1 || bitsPerSample != 8)
            throw new FormatException($"Unsupported audio body: ch={channels} bits={bitsPerSample}");

        short[] pcm16;
        if (body.Length == AudioMetaByteLengthLegacy + numSamples)
        {
            var u8 = new byte[numSamples];
            Buffer.BlockCopy(body, AudioMetaByteLengthLegacy, u8, 0, numSamples);
            pcm16 = Unsigned8ToPcm16Linear(u8);
        }
        else if (body.Length >= AudioMetaByteLength + numSamples)
        {
            var peakAbs = ReadUInt16Be(body, 8);
            if (peakAbs == 0) peakAbs = 1;
            var u8 = new byte[numSamples];
            Buffer.BlockCopy(body, AudioMetaByteLength, u8, 0, numSamples);
            pcm16 = Unsigned8ToPcm16Scaled(u8, peakAbs);
        }
        else
        {
            throw new FormatException("Audio body truncated");
        }

        return new WavFile(sampleRate, 1, 16, pcm16);
    }

    /// <summary>Upsample recovered 8 kHz payload for play/save player compatibility.</summary>
    public static WavFile PrepareAudioForExport(WavFile wav)
    {
        var mono = wav.ToMono();
        if (mono.SampleRate == PayloadAudioDefaults.ExportSampleRate)
            return new WavFile(mono.SampleRate, 1, 16, (short[])mono.Samples.Clone());
        var pcm = ResampleMono16(
            mono.Samples,
            mono.SampleRate,
            PayloadAudioDefaults.ExportSampleRate);
        return new WavFile(PayloadAudioDefaults.ExportSampleRate, 1, 16, pcm);
    }

    public static int BitLengthForText(string text)
    {
        var bodyLen = Encoding.UTF8.GetByteCount(text);
        return (HeaderByteLength + bodyLen) * 8;
    }

    public static int BitLengthForAudio(WavFile wav)
    {
        var body = EncodeAudioBody(wav);
        return (HeaderByteLength + body.Length) * 8;
    }

    public static int BitLengthForImage(byte[] imageFileBytes) =>
        (HeaderByteLength + imageFileBytes.Length) * 8;

    private static StegoPayloadResult TryDecodeText(byte[] body)
    {
        try
        {
            return StegoPayloadResult.FromText(Encoding.UTF8.GetString(body));
        }
        catch (DecoderFallbackException)
        {
            return StegoPayloadResult.Unsupported(StegoPayloadType.Text, body);
        }
    }

    private static StegoPayloadResult TryDecodeAudio(byte[] body)
    {
        try
        {
            return StegoPayloadResult.FromAudio(DecodeAudioBody(body));
        }
        catch (FormatException)
        {
            return StegoPayloadResult.Unsupported(StegoPayloadType.Audio, body);
        }
    }

    private static short[] ResampleMono16(short[] input, int fromRate, int toRate)
    {
        if (fromRate == toRate || input.Length == 0)
            return (short[])input.Clone();
        var outLen = Math.Max(1, (int)Math.Round(input.Length * (double)toRate / fromRate));
        var output = new short[outLen];
        for (var i = 0; i < outLen; i++)
        {
            var src = i * (double)fromRate / toRate;
            var i0 = Math.Clamp((int)Math.Floor(src), 0, input.Length - 1);
            var i1 = Math.Clamp(i0 + 1, 0, input.Length - 1);
            var t = src - i0;
            var v = input[i0] * (1.0 - t) + input[i1] * t;
            output[i] = (short)Math.Clamp((int)Math.Round(v), short.MinValue, short.MaxValue);
        }
        return output;
    }

    private static (byte[] U8, int PeakAbs) Pcm16ToUnsigned8PeakNormalized(short[] pcm16)
    {
        if (pcm16.Length == 0)
            return (Array.Empty<byte>(), 1);

        double sum = 0;
        foreach (var s in pcm16)
            sum += s;
        var mean = sum / pcm16.Length;
        var peak = 1.0;
        var centered = new double[pcm16.Length];
        for (var i = 0; i < pcm16.Length; i++)
        {
            var c = pcm16[i] - mean;
            centered[i] = c;
            var a = Math.Abs(c);
            if (a > peak) peak = a;
        }

        var peakAbs = Math.Clamp((int)Math.Round(peak), 1, 32767);
        var output = new byte[pcm16.Length];
        var scale = 127.0 / peakAbs;
        for (var i = 0; i < pcm16.Length; i++)
            output[i] = (byte)Math.Clamp((int)Math.Round(centered[i] * scale + 128.0), 0, 255);
        return (output, peakAbs);
    }

    private static short[] Unsigned8ToPcm16Scaled(byte[] u8, int peakAbs)
    {
        var output = new short[u8.Length];
        var scale = peakAbs / 127.0;
        for (var i = 0; i < u8.Length; i++)
            output[i] = (short)Math.Clamp((int)Math.Round((u8[i] - 128) * scale), short.MinValue, short.MaxValue);
        return output;
    }

    private static short[] Unsigned8ToPcm16Linear(byte[] u8)
    {
        var output = new short[u8.Length];
        for (var i = 0; i < u8.Length; i++)
            output[i] = (short)Math.Clamp((u8[i] << 8) - 32768, short.MinValue, short.MaxValue);
        return output;
    }

    private static void WriteUInt16Be(byte[] buf, int offset, ushort value)
    {
        buf[offset] = (byte)(value >> 8);
        buf[offset + 1] = (byte)(value & 0xFF);
    }

    private static void WriteUInt32Be(byte[] buf, int offset, uint value)
    {
        buf[offset] = (byte)((value >> 24) & 0xFF);
        buf[offset + 1] = (byte)((value >> 16) & 0xFF);
        buf[offset + 2] = (byte)((value >> 8) & 0xFF);
        buf[offset + 3] = (byte)(value & 0xFF);
    }

    private static ushort ReadUInt16Be(byte[] buf, int offset) =>
        (ushort)((buf[offset] << 8) | buf[offset + 1]);

    private static uint ReadUInt32Be(byte[] buf, int offset) =>
        ((uint)buf[offset] << 24)
        | ((uint)buf[offset + 1] << 16)
        | ((uint)buf[offset + 2] << 8)
        | buf[offset + 3];
}
