using System.Text.Json;

namespace AudioStegano.Core.Stego;

/// <summary>Port of MATLAB <c>feedforwardnet(10)</c> 8-10-8 — <c>train/train_autoencoder.m</c>.</summary>
public sealed class MessageBlockAutoencoder
{
    public const int BlockSize = 8;
    public const int HiddenSize = 10;

    private readonly double[][] _iw;
    private readonly double[][] _lw;
    private readonly double[] _b1;
    private readonly double[] _b2;

    private MessageBlockAutoencoder(double[][] iw, double[][] lw, double[] b1, double[] b2)
    {
        _iw = iw;
        _lw = lw;
        _b1 = b1;
        _b2 = b2;
    }

    public static MessageBlockAutoencoder LoadEmbedded()
    {
        var asm = typeof(MessageBlockAutoencoder).Assembly;
        const string name = "AudioStegano.Core.Stego.trained_autoencoder.json";
        using var stream = asm.GetManifestResourceStream(name)
            ?? throw new InvalidOperationException($"Missing embedded resource {name}");
        using var reader = new StreamReader(stream);
        return FromJson(reader.ReadToEnd());
    }

    public static MessageBlockAutoencoder FromJson(string json)
    {
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        return new MessageBlockAutoencoder(
            ReadMatrix(root, "iw"),
            ReadMatrix(root, "lw"),
            ReadVector(root, "b1"),
            ReadVector(root, "b2"));
    }

    public int[] EncodeRounded(ReadOnlySpan<byte> msgBits)
    {
        if (msgBits.Length % BlockSize != 0)
            throw new ArgumentException($"Length must be a multiple of {BlockSize}");
        var nBlocks = msgBits.Length / BlockSize;
        var outVals = new int[msgBits.Length];
        var x = new double[BlockSize];
        for (var b = 0; b < nBlocks; b++)
        {
            for (var i = 0; i < BlockSize; i++)
                x[i] = msgBits[b * BlockSize + i];
            var y = ForwardColumn(x);
            for (var i = 0; i < BlockSize; i++)
                outVals[b * BlockSize + i] = (int)Math.Round(y[i]);
        }
        return outVals;
    }

    public byte[] DecodeBits(ReadOnlySpan<byte> payload)
    {
        if (payload.Length % BlockSize != 0)
            throw new ArgumentException($"Length must be a multiple of {BlockSize}");
        var nBlocks = payload.Length / BlockSize;
        var outBits = new byte[payload.Length];
        var x = new double[BlockSize];
        for (var b = 0; b < nBlocks; b++)
        {
            for (var i = 0; i < BlockSize; i++)
                x[i] = payload[b * BlockSize + i];
            var y = ForwardColumn(x);
            for (var i = 0; i < BlockSize; i++)
                outBits[b * BlockSize + i] = (byte)((int)Math.Round(y[i]) & 1);
        }
        return outBits;
    }

    public static int XorPayloadBit(int encodedRounded, int keyBit)
    {
        var a = encodedRounded != 0;
        var b = keyBit != 0;
        return a != b ? 1 : 0;
    }

    public static byte[] BuildPayload(int[] encodedRounded, byte[] key)
    {
        if (encodedRounded.Length != key.Length)
            throw new ArgumentException("encoded and key must have the same length");
        var payload = new byte[encodedRounded.Length];
        for (var i = 0; i < encodedRounded.Length; i++)
            payload[i] = (byte)XorPayloadBit(encodedRounded[i], key[i]);
        return payload;
    }

    private double[] ForwardColumn(double[] x)
    {
        var n1 = new double[HiddenSize];
        for (var j = 0; j < HiddenSize; j++)
        {
            var sum = _b1[j];
            for (var i = 0; i < BlockSize; i++)
                sum += _iw[j][i] * x[i];
            n1[j] = Tansig(sum);
        }

        var output = new double[BlockSize];
        for (var k = 0; k < BlockSize; k++)
        {
            var sum = _b2[k];
            for (var j = 0; j < HiddenSize; j++)
                sum += _lw[k][j] * n1[j];
            output[k] = Tansig(sum);
        }
        return output;
    }

    private static double Tansig(double n) =>
        2.0 / (1.0 + Math.Exp(-2.0 * Math.Clamp(n, -500, 500))) - 1.0;

    private static double[][] ReadMatrix(JsonElement root, string name)
    {
        var rows = root.GetProperty(name);
        var matrix = new double[rows.GetArrayLength()][];
        var i = 0;
        foreach (var row in rows.EnumerateArray())
        {
            var cols = row.GetArrayLength();
            matrix[i] = new double[cols];
            var j = 0;
            foreach (var v in row.EnumerateArray())
                matrix[i][j++] = v.GetDouble();
            i++;
        }
        return matrix;
    }

    private static double[] ReadVector(JsonElement root, string name)
    {
        var arr = root.GetProperty(name);
        var vec = new double[arr.GetArrayLength()];
        var i = 0;
        foreach (var v in arr.EnumerateArray())
            vec[i++] = v.GetDouble();
        return vec;
    }
}
